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

  it "can be unbound from amq.fanout" do
    exchange = channel.exchange("amq.fanout", :type => :fanout, :durable => true, :auto_delete => false)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange)

    exchange.publish("", :routing_key => queue.name)
    expect(queue.get).not_to be_nil

    queue.unbind(exchange)

    exchange.publish("")
    expect(queue.get).to be_nil
  end


  it "can be unbound from a client-declared exchange" do
    exchange = channel.exchange("hot.bunnies.fanout#{Time.now.to_i}", :type => :fanout, :durable => false)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange)

    exchange.publish("", :routing_key => queue.name)
    expect(queue.get).not_to be_nil

    queue.unbind(exchange)

    exchange.publish("")
    expect(queue.get).to be_nil
  end
end
