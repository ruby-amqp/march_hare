require "spec_helper"

describe "Any channel" do

  #
  # Environment
  #

  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  let(:latch) { java.util.concurrent.CountDownLatch.new(1) }

  class ConfirmationListener
    include com.rabbitmq.client.ConfirmListener

    def initialize(latch)
      @latch = latch
    end

    def handle_ack(delivery_tag, multiple)
      @latch.count_down
    end

    def handle_nack(delivery_tag, multiple)
      @latch.count_down
    end
  end


  #
  # Examples
  #

  it "can use publisher confirmations with listener objects" do
    channel.confirm_select
    channel.confirm_listener = ConfirmationListener.new(latch)

    queue = channel.queue("", :auto_delete => true)
    Thread.new do
      channel.default_exchange.publish("", :routing_key => queue.name)
    end

    latch.await
  end
end
