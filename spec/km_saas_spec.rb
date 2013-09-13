require 'setup'
require 'kmts/saas'
describe KMTS do
  before do
    KMTS::reset
    now = Time.now
    Time.stub!(:now).and_return(now)
    FileUtils.rm_f KMTS::log_name(:error)
    FileUtils.rm_f KMTS::log_name(:query)
    Helper.clear
  end

  describe "should record events" do
    before do
      KMTS::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292'
    end
    context "plain usage" do
      it "records a signup event" do
        KMTS.signed_up 'bob', 'Premium'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Signed Up'
        res[:query]['Plan Name'].first.should == 'Premium'
      end
      it "records an upgraded event" do
        KMTS.upgraded 'bob', 'Unlimited'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Upgraded'
        res[:query]['Plan Name'].first.should == 'Unlimited'
      end
      it "records a downgraded event" do
        KMTS.downgraded 'bob', 'Free'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Downgraded'
        res[:query]['Plan Name'].first.should == 'Free'
      end
      it "records a billed event" do
        KMTS.billed 'bob', 32, 'Upgraded'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Billed'
        res[:query]['Billing Amount'].first.should == '32'
        res[:query]['Billing Description'].first.should == 'Upgraded'
      end
      it "records a canceled event" do
        KMTS.canceled 'bob'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Canceled'
      end
      it "records a visited site event" do
        KMTS.visited_site 'bob', 'http://duckduckgo.com', 'http://kissmetrics.com'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_n'].first.should == 'Visited Site'
        res[:query]['URL'].first.should == 'http://duckduckgo.com'
        res[:query]['Referrer'].first.should == 'http://kissmetrics.com'
      end
    end
    context "usage with props" do
      it "records a signup event" do
        KMTS.signed_up 'bob', 'Premium', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
      it "records an upgraded event" do
        KMTS.upgraded 'bob', 'Unlimited', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
      it "records a downgraded event" do
        KMTS.downgraded 'bob', 'Free', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
      it "records a billed event" do
        KMTS.billed 'bob', 32, 'Upgraded', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
      it "records a canceled event" do
        KMTS.canceled 'bob', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
      it "records a visited site event" do
        KMTS.visited_site 'bob', 'http://duckduckgo.com', 'http://kissmetrics.com', :foo => 'bar'
        sleep 0.1
        res = Helper.accept(:history).first.indifferent
        res[:query]['foo'].first.should == 'bar'
      end
    end
  end
end
