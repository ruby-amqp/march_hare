require "spec_helper"

describe "Any channel" do

  #
  # Environment
  #

  let(:connection) { CarrotCake.connect }

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
end
