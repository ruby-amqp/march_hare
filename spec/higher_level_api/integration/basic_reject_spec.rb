RSpec.describe MarchHare::Channel, "#reject" do
  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end

  context "with a valid (known) delivery tag" do
    let(:ch)    { connection.create_channel }

    context "with requeue = true" do
      it "requeues a message" do
        q = ch.queue("bunny.basic.reject.manual-acks", :exclusive => true)
        x = ch.default_exchange

        x.publish("bunneth", :routing_key => q.name)
        sleep(0.5)
        expect(q.message_count).to eq(1)
        meta, _ = q.pop(:ack => true)

        ch.reject(meta.delivery_tag, true)
        sleep(0.5)
        expect(q.message_count).to eq(1)

        ch.close
      end
    end

    context "with requeue = false" do
      it "rejects a message" do
        q = ch.queue("bunny.basic.reject.with-requeue-false", :exclusive => true)
        x = ch.default_exchange

        x.publish("bunneth", :routing_key => q.name)
        sleep(0.5)
        expect(q.message_count).to eq(1)
        delivery_info, _, _ = q.pop(:ack => true)

        ch.reject(delivery_info.delivery_tag, false)
        sleep(0.5)
        expect(q.message_count).to eq(0)

        ch.close
      end
    end
  end
end
