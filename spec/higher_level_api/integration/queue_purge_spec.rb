describe "Any queue" do

  #
  # Environment
  #

  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end


  #
  # Examples
  #

  it "can be purged" do
    exchange = channel.exchange("amq.fanout", :type => :fanout, :durable => true, :auto_delete => false)
    queue    = channel.queue("", :auto_delete => true)
    exchange.publish("")
    expect(queue.get).to be_nil
    queue.purge
    expect(queue.get).to be_nil

    queue.bind(exchange)

    exchange.publish("", :routing_key => queue.name)
    expect(queue.get).not_to be_nil
    queue.purge
    expect(queue.get).to be_nil
    queue.delete
  end
end
