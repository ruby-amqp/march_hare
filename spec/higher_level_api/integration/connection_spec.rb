require "spec_helper"


describe "HotBunnies.connect" do

  #
  # Examples
  #

  it "lets you specify requested heartbeat interval" do
    c1 = HotBunnies.connect(:requested_heartbeat => 10)
    c1.close
  end

  it "lets you specify connection timeout interval" do
    c1 = HotBunnies.connect(:connection_timeout => 3)
    c1.close
  end

  if !ENV["CI"] && ENV["TLS_TESTS"]
    it "supports TLS w/o custom protocol or trust manager" do
      c1 = HotBunnies.connect(:tls => true, :port => 5671)
      c1.close
    end
  end

  context "when connection fails due to unknown host" do
    it "raises an exception" do
      lambda {
        HotBunnies.connect(:hostname => "a8s878787s8d78sd78.lol")
      }.should raise_error(HotBunnies::ConnectionRefused)
    end
  end

  context "when connection fails due to RabbitMQ node not running" do
    it "raises an exception" do
      lambda {
        HotBunnies.connect(:hostname => "hotbunnies.info")
      }.should raise_error(HotBunnies::ConnectionRefused)
    end
  end

  context "when connection fails due to invalid credentials" do
    it "raises an exception" do
      lambda {
        HotBunnies.connect(:username => "this$username%does*not&exist")
      }.should raise_error(HotBunnies::PossibleAuthenticationFailureError)
    end
  end

  it "lets you specify executor (thread pool) factory" do
    calls = 0
    factory = double(:executor_factory)
    factory.stub(:call) do
      calls += 1
      HotBunnies::JavaConcurrent::Executors.new_cached_thread_pool
    end
    c1 = HotBunnies.connect(:executor_factory => factory)
    c1.close
    c1.automatically_recover
    c1.close
    calls.should == 2
  end
end


describe "HotBunnies::Session#start" do
  it "is a no-op added for better compatibility with Bunny and to guard non-idempotent AMQConnection#start" do
    c = HotBunnies.connect
    100.times do
      c.start
    end

    c.close
  end
end
