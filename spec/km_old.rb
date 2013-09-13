require 'setup'

describe KMTS do
  attr_accessor :send_query, :log
  before do
    @send_query = []
    @log = []
    KMTS.stub(:send_query).and_return { |*args| send_query << args }
    KMTS.stub(:log).and_return { |*args| log << Hash[*args] }
    time = Time.at 1234567890
    Time.stub!(:now).and_return(time)
    KMTS.reset
  end
  context "initialization" do
    it "should not record without initialization" do
      KMTS::record 'My Action'
      log.first[:error].should =~ /Need to initialize first \(KMTS::init <your_key>\)/
    end
    it "should not set initialization" do
      KMTS::set :day => 'friday'
      log.first[:error].should =~ /Need to initialize first \(KMTS::init <your_key>\)/
    end
  end
  context "identification" do
    before do
      KMTS::init 'KM_KEY'
    end
    it "should not record without identification" do
      KMTS::record 'My Action'
      log.first[:error].should include("Need to identify first (KMTS::identify <user>)")
    end
    it "should set without identification" do
      KMTS::record 'My Action'
      log.first[:error].should include("Need to identify first (KMTS::identify <user>)")
    end

    context "aliasing" do
      it "shouldn't fail on alias without identifying" do
        KMTS::alias 'peter','joe' # Alias "bob" to "robert"
        send_query.first.first.should have_query_string("/a?_n=joe&_p=peter&_k=KM_KEY&_t=1234567890")
      end
    end
  end

  context "events" do
    before do
      KMTS::init 'KM_KEY'
      KMTS::identify 'bob'
    end
    it "should record an action with no specific props" do
      KMTS::record 'My Action'
      send_query.first.first.should have_query_string("/e?_n=My+Action&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should record an action with properties" do
      KMTS::record 'Signup', 'age' => 26
      send_query.first.first.should have_query_string("/e?age=26&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should reocrd properties with spaces in key and value" do
      KMTS::record 'Signup', 'age' => 26, 'city of residence' => 'eug ene'
      send_query.first.first.should have_query_string("/e?age=26&city+of+residence=eug+ene&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should not over-write special keys" do
      KMTS::record 'Signup', 'age' => 26, '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      send_query.first.first.should have_query_string("/e?age=26&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should not over-write special keys with symbols" do
      KMTS::record 'Signup', 'age' => 26, '_p' => 'billybob', :'_k' => 'foo', :'_n' => 'something else'
      send_query.first.first.should have_query_string("/e?age=26&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should work with properties with @" do
      KMTS::record 'Signup', 'email' => 'test@blah.com', '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      send_query.first.first.should have_query_string("/e?email=test%40blah.com&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should work with just set" do
      KMTS::record 'age' => 26
      send_query.first.first.should have_query_string("/s?age=26&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should record ok with multiple calls" do
      KMTS::record 'Signup', 'age' => 26
      KMTS::record 'Signup', 'age' => 36
      send_query.first.first.should have_query_string("/e?age=26&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "shouldn't store the key anywhere" do
      KMTS::init 'KM_OTHER'
      KMTS::alias 'truman','harry' # Alias "bob" to "robert"
      send_query.first.first.should have_query_string("/a?_n=harry&_p=truman&_k=KM_OTHER&_t=1234567890")
    end
    it "should override the time if defined" do
      KMTS::record 'Signup', 'age' => 36, '_t' => 1234567891
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567891&_d=1")
    end
    it "should work with either symbols or strings" do
      KMTS::record :Signup, :age => 36, :_t => 1234567891
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567891&_d=1")
    end
  end

  it "should test cron" do
    pending
  end
  it "should send logged queries" do
    pending
  end
end
