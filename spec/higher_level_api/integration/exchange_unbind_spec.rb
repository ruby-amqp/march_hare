RSpec.describe MarchHare::Exchange do
  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end

  it "unbinds two existing exchanges" do
    ch          = connection.create_channel

    source      = ch.fanout("bunny.exchanges.source#{rand}")
    destination = ch.fanout("bunny.exchanges.destination#{rand}")

    queue       = ch.queue("", :exclusive => true)
    queue.bind(destination)

    destination.bind(source)
    source.publish("")
    sleep 0.5

    expect(queue.message_count).to eq(1)
    queue.pop(:ack => true)

    destination.unbind(source)
    source.publish("")
    sleep 0.5

    expect(queue.message_count).to eq(0)

    source.delete
    destination.delete
    ch.close
  end
end
