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
end
