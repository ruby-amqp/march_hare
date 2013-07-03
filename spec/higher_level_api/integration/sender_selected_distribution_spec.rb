require "spec_helper"

describe "Any AMQP 0.9.1 client using RabbitMQ" do

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

  it "can have use CC and BCC headers for sender selected routing" do
    queue1 = channel.queue("", :exclusive => true)
    queue2 = channel.queue("", :exclusive => true)
    queue3 = channel.queue("", :exclusive => true)
    queue4 = channel.queue("", :exclusive => true)

    channel.default_exchange.publish("1010", :properties => {
                                       :headers => {
                                         "CC"  => [queue2.name],
                                         "BCC" => [queue3.name]
                                       }
                                     }, :routing_key => queue1.name)

    sleep 1

    mc1, _ = queue1.status
    mc2, _ = queue2.status
    mc3, _ = queue3.status
    mc4, _ = queue4.status

    mc1.should == 1
    mc2.should == 1
    mc3.should == 1
    mc4.should == 0
  end
end
