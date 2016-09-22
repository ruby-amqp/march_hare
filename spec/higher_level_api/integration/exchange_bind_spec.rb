RSpec.describe MarchHare::Exchange do
  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end

  it "should bind two exchanges using exchange instances" do
    ch          = connection.create_channel
    source      = ch.fanout("hot_bunnies.spec.exchanges.source", :auto_delete => true)
    destination = ch.fanout("hot_bunnies.spec.exchanges.destination", :auto_delete => true)

    queue = ch.queue("", :exclusive => true)
    queue.bind(destination)

    destination.bind(source)
    source.publish("")
    expect(queue.get).not_to be_nil
  end

  it "should bind two exchanges using exchange name" do
    ch          = connection.create_channel
    source      = ch.fanout("hot_bunnies.spec.exchanges.source", :auto_delete => true)
    destination = ch.fanout("hot_bunnies.spec.exchanges.destination", :auto_delete => true)

    queue = ch.queue("", :exclusive => true)
    queue.bind(destination)

    destination.bind(source.name)
    source.publish("")
    expect(queue.get).not_to be_nil
  end
end
