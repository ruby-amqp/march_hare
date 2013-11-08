require "spec_helper"

describe "Any channel" do

  #
  # Environment
  #

  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end


  #
  # Examples
  #

  it "can use publisher confirmations" do
    ch = connection.create_channel
    q  = ch.queue("", :exclusive => true)

    ch.confirm_select
    ch.default_exchange.publish("", :routing_key => q.name)

    ch.wait_for_confirms(400)

    true.should be_true
  end

  it "can receive publisher confirmation acks" do
    got_ack = false
    ch = connection.create_channel
    q  = ch.queue("", :exclusive => true)

    ch.confirm_select
    ch.on_confirm { |type, seq, multiple| got_ack = (type ==:ack) }

    ch.default_exchange.publish("", :routing_key => q.name)

    ch.wait_for_confirms(40)

    got_ack.should be_true
  end
end
