require "spec_helper"


describe "Queue" do
  context "with a server-generated name" do
    let(:connection) { HotBunnies.connect }    
    let(:channel) { connection.create_channel }

    it "can be declared" do
      channel.queue("", :auto_delete => true)
      channel.close
      connection.close
    end
  end
end