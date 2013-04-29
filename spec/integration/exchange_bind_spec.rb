require "spec_helper"

describe HotBunnies::Exchange do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "should bind two exchanges using exchange instances" do
    source =       channel.exchange("hot_bunnies.spec.exchanges.source", :auto_delete => true)
    destination = channel.exchange("hot_bunnies.spec.exchanges.destination", :auto_delete => true)

    queue = channel.queue("", :auto_delete => true)
    queue.bind(destination)

    destination.bind(source)
    source.publish("")
    queue.get.should_not be_nil
  end

  it "should bind two exchanges using exchange name" do
    source =       channel.exchange("hot_bunnies.spec.exchanges.source", :auto_delete => true)
    destination = channel.exchange("hot_bunnies.spec.exchanges.destination", :auto_delete => true)

    queue = channel.queue("", :auto_delete => true)
    queue.bind(destination)

    destination.bind(source.name)
    source.publish("")
    queue.get.should_not be_nil
  end
end
