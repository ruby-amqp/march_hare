RSpec.describe MarchHare::Channel, "#ack" do
  let(:connection) { MarchHare.connect }

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
      expect(q.message_count).to eq(1)
      meta, content = q.pop(:ack => true)

      ch.ack(meta.delivery_tag, true)
      expect(meta.delivery_tag.to_i).to eq(1)

      sleep(0.25)
      expect(q.message_count).to eq(0)

      expect(ch).to be_open
      ch.close
    end
  end
end
