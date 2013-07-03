require "spec_helper"

describe "Any exchange" do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end


  #
  # Examples
  #

  it "can have an alternate exchange (a RabbitMQ-specific extension to AMQP 0.9.1)" do
    ch = connection.create_channel
    q  = ch.queue("", :exclusive => true)

    fe = ch.fanout("hot_bunnies.extensions.alternate_xchanges.fanout1")
    de = ch.direct("hot_bunnies.extensions.alternate_xchanges.direct1", :arguments => {
                               "alternate-exchange" => fe.name
                             })

    q.bind(fe)
    de.publish("1010", :routing_key => "", :mandatory => true)

    q.message_count.should == 1
  end
end
