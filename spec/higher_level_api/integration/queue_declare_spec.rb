require "spec_helper"


describe "Queue" do
  context "with a server-generated name" do
    let(:connection) { CarrotCake.connect }
    let(:channel)    { connection.create_channel }

    after :each do
      channel.close
      connection.close
    end

    it "can be declared as auto-deleted" do
      q = channel.queue("", :auto_delete => true)
      q.should be_auto_delete
      q.delete
    end

    it "can be declared as auto-deleted and non-durable" do
      q = channel.queue("", :auto_delete => true, :durable => false)
      q.should be_auto_delete
      q.should_not be_durable
      q.delete
    end

    it "can be declared as NON-auto-deleted" do
      q = channel.queue("", :auto_delete => false)
      q.should_not be_auto_delete
      q.should_not be_durable
      q.delete
    end

    it "can be declared as NON-durable" do
      q = channel.queue("", :durable => false)
      q.should_not be_durable
      q.delete
    end

    it "can be declared with additional attributes like x-message-ttle" do
      q = channel.queue("", :durable => false, :arguments => { 'x-message-ttl' => 2000 })
      x = channel.exchange("", :type => :direct)

      100.times do |i|
        x.publish("Message #{i}", :routing_key => q.name)
      end

      q.get.should_not be_nil
      sleep(2.1)

      q.get.should be_nil
      q.delete
    end
  end
end
