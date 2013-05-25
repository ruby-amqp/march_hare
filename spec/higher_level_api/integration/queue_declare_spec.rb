require "spec_helper"


describe "Queue" do
  context "with a server-generated name" do
    let(:connection) { HotBunnies.connect }
    let(:channel)    { connection.create_channel }

    after :each do
      channel.close
      connection.close
    end

    it "can be declared as auto-deleted" do
      channel.queue("", :auto_delete => true)
    end

    it "can be declared as auto-deleted and non-durable" do
      channel.queue("", :auto_delete => true, :durable => false)
    end

    it "can be declared as NON-auto-deleted" do
      channel.queue("", :auto_delete => false)
    end

    it "can be declared as NON-durable" do
      channel.queue("", :durable => false)
    end

    it "can be declared with additional attributes like x-message-ttle" do
      queue    = channel.queue("", :durable => false, :arguments => { 'x-message-ttl' => 2000 })
      exchange = channel.exchange("", :type => :direct)

      100.times do |i|
        exchange.publish("Message #{i}", :routing_key => queue.name)
      end

      queue.get.should_not be_nil
      sleep(2.1)

      queue.get.should be_nil
    end
  end
end
