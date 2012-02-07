require "spec_helper"


describe "HotBunnies" do

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
end
