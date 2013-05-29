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
      }.should raise_error(java.net.UnknownHostException)
    end
  end

  context "when connection fails due to RabbitMQ node not running" do
    it "raises an exception" do
      lambda {
        HotBunnies.connect(:hostname => "hotbunnies.info")
      }.should raise_error(java.net.ConnectException)
    end
  end

  context "when connection fails due to invalid credentials" do
    it "raises an exception" do
      lambda {
        HotBunnies.connect(:username => "this$username%does*not&exist")
      }.should raise_error(HotBunnies::PossibleAuthenticationFailureError)
    end
  end
end
