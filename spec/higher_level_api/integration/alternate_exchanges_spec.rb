RSpec.describe "Any exchange" do
  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end


  #
  # Examples
  #

  it "can have an alternate exchange (a RabbitMQ-specific extension to AMQP 0.9.1)" do
    ch = connection.create_channel
    q  = ch.queue("", :exclusive => true)

    fe = ch.fanout("march_hare.extensions.alternate_xchanges.fanout1")
    de = ch.direct("march_hare.extensions.alternate_xchanges.direct1", :arguments => {
                               "alternate-exchange" => fe.name
                             })

    q.bind(fe)
    de.publish("1010", :routing_key => "", :mandatory => true)

    expect(q.message_count).to eq(1)
  end
end
