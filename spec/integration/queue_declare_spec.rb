require "spec_helper"


describe "Queue" do
  context "with a server-generated name" do
    let(:connection) { HotBunnies.connect }    
    let(:channel) { connection.create_channel }

    after :all do
      channel.close
      connection.close      
    end

    it "can be declared" do
      channel.queue("", :auto_delete => true)
    end
  end
end