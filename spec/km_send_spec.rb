require 'setup'

describe 'km_send' do
  context "using cron for sending logs" do
    before do
      now = Time.now
      Dir.glob(__('log','*')).each do |file|
        FileUtils.rm file
      end
      KMTS.reset
      Helper.clear
    end

    context "with default environment" do
      before do
        KMTS::init 'KM_KEY', :log_dir => __('log'), :host => 'http://127.0.0.1:9292', :use_cron => true, :env => 'production'
      end
      it "should test commandline version" do
        KMTS::record 'bob', 'Signup', 'age' => 26
        `bundle exec km_send #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_d'].first.should == '1'
        res[:query]['_t'].first.to_i.should be_within(10.0).of(Time.now.to_i)
        res[:query]['age'].first.should == '26'
      end
      it "should send from query_log" do
        write_log :query, "/e?_t=1297105499&_n=Signup&_p=bob&_k=KM_KEY&age=26"
        `bundle exec km_send #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_t'].first.should == '1297105499'
        res[:query]['age'].first.should == '26'
      end
      it "should send from query_log_old" do
        write_log :query_old, "/e?_t=1297105499&_n=Signup&_p=bob&_k=KM_KEY&age=26"
        `bundle exec km_send #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_t'].first.should == '1297105499'
        res[:query]['age'].first.should == '26'
      end
      it "should send from both query_log and query_log_old" do
        File.open(__('log/kissmetrics_query.log'), 'w+') { |h| h.puts "/e?_t=1297105499&_n=Signup&_p=bob&_k=KM_KEY&age=27" }
        File.open(__('log/kissmetrics_production_query.log'), 'w+') { |h| h.puts "/e?_t=1297105499&_n=Signup&_p=bob&_k=KM_KEY&age=26" }
        `bundle exec km_send #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_t'].first.should == '1297105499'
        res[:query]['age'].first.should == '27'
        Helper.clear
        `bundle exec km_send #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_t'].first.should == '1297105499'
        res[:query]['age'].first.should == '26'
      end
      it "sends unless dryrun is specified" do
        File.open(__('log/kissmetrics_alpha_query.log'), 'w+') { |h| h.puts "/e?_t=1297105499&_n=Signup&_p=bob&_k=KM_KEY&age=26" }
        `bundle exec km_send -e alpha #{__('log/')} http://127.0.0.1:9292`
        sleep 0.1
        res = Helper.accept(:history).first.should_not be_nil
      end
    end
    it "should send from diff environment when force flag is used" do
      KMTS::init 'KM_KEY', :log_dir => __('log'), :host => 'http://127.0.0.1:9292', :use_cron => true, :env => 'development', :force => true
      KMTS::record 'bob', 'Signup', 'age' => 26
      `bundle exec km_send -f -e development #{__('log/')} http://127.0.0.1:9292`
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_d'].first.should == '1'
      res[:query]['_t'].first.to_i.should be_within(10.0).of(Time.now.to_i)
      res[:query]['age'].first.should == '26'
    end
  end
end
