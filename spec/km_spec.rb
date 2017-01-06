require 'setup'
describe KMTS do
  before do
    KMTS::reset
    FileUtils.rm_f KMTS::log_name(:error)
    FileUtils.rm_f KMTS::log_name(:query)
    Helper.clear
  end

  it "shouldn't write at all without init" do
    KMTS::record 'my_id', 'My Action'
    IO.readlines(KMTS::log_name(:error)).join.should =~ /Need to initialize first \(KMTS::init <your_key>\)/

    FileUtils.rm_f KMTS::log_name(:error)
    KMTS::set 'my_id', :day => 'friday'
    IO.readlines(KMTS::log_name(:error)).join.should =~ /Need to initialize first \(KMTS::init <your_key>\)/
  end

  it "shouldn't fail on alias without identifying" do
    KMTS::init 'KM_OTHER', :log_dir => __('log'), :host => 'http://127.0.0.1:9292'
    KMTS::alias 'peter','joe' # Alias "bob" to "robert"
    sleep 0.1
    res = Helper.accept(:history).first.indifferent
    res[:path].should == '/a'
    res[:query]['_k'].first.should == 'KM_OTHER'
    res[:query]['_p'].first.should == 'peter'
    res[:query]['_n'].first.should == 'joe'
    res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
  end

  it "shouldn't fail on alias without identifying from commandline" do
    KMTS::init 'KM_OTHER', :log_dir => __('log'), :host => 'http://127.0.0.1:9292'
    KMTS::alias 'peter','joe' # Alias "bob" to "robert"
    sleep 0.1
    res = Helper.accept(:history).first.indifferent
    res[:path].should == '/a'
    res[:query]['_k'].first.should == 'KM_OTHER'
    res[:query]['_p'].first.should == 'peter'
    res[:query]['_n'].first.should == 'joe'
    res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
  end

  it "should allow sending to https endpoints" do
    lambda do
      allow(KMTS).to receive(:log_error).and_raise('Error')
      KMTS::init 'KM_OTHER', :log_dir => __('log'), :host => 'https://trk.kissmetrics.com/'
      KMTS::record 'bob', 'My Action'
    end.should_not raise_error
  end

  describe "should record events" do
    before do
      KMTS::init 'KM_KEY', :log_dir => __('log'), :host => 'http://127.0.0.1:9292'
    end
    it "records an action with no action-specific properties" do
      KMTS::record 'bob', 'My Action'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'My Action'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
    end
    it "records an action with properties" do
      KMTS::record 'bob', 'Signup', 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
    end
    it "should be able to hace spaces in key and value" do
      KMTS::record 'bob', 'Signup', 'age' => 26, 'city of residence' => 'eug ene'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
      res[:query]['city of residence'].first.should == 'eug ene'
    end
    it "should not override important parts" do
      KMTS::record 'bob', 'Signup', 'age' => 26, '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
    end
    it "should work with propps using @" do
      KMTS::record 'bob', 'Signup', 'email' => 'test@blah.com', '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['email'].first.should == 'test@blah.com'
    end
    it "should just set properties without event" do
      KMTS::record 'bob', 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/s'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
    end
    it "should be able to use km set directly" do
      KMTS::set 'bob', 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/s'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
    end
    it "should work with multiple lines" do
      # testing recording of multiple lines.
      KMTS::record 'bob', 'Signup', 'age' => 26
      sleep 0.1
      KMTS::record 'bob', 'Signup', 'age' => 36
      sleep 0.1
      res = Helper.accept(:history)[0].indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 26.to_s
      res = Helper.accept(:history)[1].indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 36.to_s
    end
    it "should not have key hardcoded anywhere" do
      KMTS::init 'KM_OTHER', :log_dir => __('log')
      KMTS::alias 'truman','harry' # Alias "bob" to "robert"
      sleep 0.1
      res = Helper.accept(:history)[0].indifferent
      res[:path].should == '/a'
      res[:query]['_k'].first.should == 'KM_OTHER'
      res[:query]['_p'].first.should == 'truman'
      res[:query]['_n'].first.should == 'harry'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
    end

    it "allows overriding of km_key" do
      KMTS::init 'KM_OTHER', :log_dir => __('log'), :force_key => false
      KMTS::record 'bob', 'Signup', 'age' => 36, '_k' => 'OTHER_KEY'
      sleep 0.1

      res = Helper.history.first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'OTHER_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 36.to_s
    end

    it "uses default key when force_key is disabled" do
      KMTS::init 'KM_OTHER', :log_dir => __('log'), :force_key => false
      KMTS::record 'bob', 'Signup', 'age' => 36
      sleep 0.1

      res = Helper.history.first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_OTHER'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.to_i.should be_within(2.0).of(Time.now.to_i)
      res[:query]['age'].first.should == 36.to_s
    end
  end
  context "reading from files" do
    before do
      Dir.glob(__('log','*')).each do |file|
        FileUtils.rm file
      end
      KMTS.reset
    end
    it "should run fine even though there's no server to connect to" do
      KMTS::init 'KM_OTHER', :log_dir => __('log'), :host => '127.0.0.1:9291', :to_stderr => false, :env => 'production'
      KMTS::record 'bob', 'My Action' # records an action with no action-specific properties;
      Helper.accept(:history).size.should == 0
      File.exists?(__('log/kissmetrics_production_query.log')).should == true
      File.exists?(__('log/kissmetrics_production_error.log')).should == true
    end
    it "should escape @ properly" do
      KMTS::init 'KM_OTHER', :log_dir => __('log'), :host => 'http://127.0.0.1:9292', :to_stderr => false, :use_cron => true
      KMTS::record 'bob', 'prop_with_@_in' # records an action with no action-specific properties;
      IO.readlines(KMTS::log_name(:query)).join.should_not contain_string('@')
    end
  end
end
