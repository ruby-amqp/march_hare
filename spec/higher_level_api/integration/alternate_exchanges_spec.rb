require "spec_helper"

describe "Any exchange" do

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

  it "can have an alternate exchange (a RabbitMQ-specific extension to AMQP 0.9.1)" do
    queue = channel.queue("", :auto_delete => true)

    fe    = channel.fanout("hot_bunnies.extensions.alternate_xchanges.fanout1")
    de    = channel.direct("hot_bunnies.extensions.alternate_xchanges.direct1", :arguments => {
                               "alternate-exchange" => fe.name
                             })

    queue.bind(fe)
    de.publish("1010", :routing_key => "", :mandatory => true)

    mc, _ = queue.status
    mc.should == 1
  end
end
