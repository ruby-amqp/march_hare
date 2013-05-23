require "spec_helper"

describe HotBunnies::Channel, "#ack" do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end

  context "with a valid (known) delivery tag" do
    let(:ch)    { connection.create_channel }

    it "acknowledges a message" do
      q = ch.queue("hotbunnies.basic.ack.manual-acks", :exclusive => true)
      x = ch.default_exchange

      x.publish("bunneth", :routing_key => q.name)
      sleep(0.25)
      q.message_count.should == 1
      meta, content = q.pop(:ack => true)

      ch.ack(meta.delivery_tag, true)
      meta.delivery_tag.should == 1

      sleep(0.25)
      q.message_count.should == 0

      ch.should be_open
      ch.close
    end
  end

  context "with an invalid (random) delivery tag" do
    it "causes an exception due to a channel-level error" do
      pending "we need to redesign exception handling first"
    end
  end
end
