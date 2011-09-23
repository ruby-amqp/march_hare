require "spec_helper"


describe "Any queue" do

  #
  # Environment
  #

  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end


  #
  # Examples
  #

  it "can be bound to amq.fanout" do
    exchange = channel.exchange("amq.fanout", :type => :fanout, :durable => true, :auto_delete => false)
    queue    = channel.queue("", :auto_delete => true)
    exchange.publish("")
    queue.get.should be_nil

    queue.bind(exchange)

    exchange.publish("", :routing_key => queue.name)
    queue.get.should_not be_nil
  end


  it "can be bound to a newly declared exchange" do
    exchange = channel.exchange("hot.bunnies.fanout", :type => :fanout, :durable => false, :auto_delete => true)
    queue    = channel.queue("", :auto_delete => true)
    exchange.publish("")
    queue.get.should be_nil

    queue.bind(exchange)

    exchange.publish("", :routing_key => queue.name)
    queue.get.should_not be_nil
  end
end
