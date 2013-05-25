require "spec_helper"

describe "A consumer" do
  let(:connection) { HotBunnies.connect }
  let(:queue_name) { "hotbunnies.queues.#{rand}" }

  after :each do
    connection.close
  end



  it "can be cancelled" do
    delivered_data = []

    t = Thread.new do
      ch         = connection.create_channel
      q          = ch.queue(queue_name, :exclusive => true)
      consumer = q.subscribe(:block => false) do |meta, payload|
        puts "consumed #{payload}"
        delivered_data << payload
      end

      consumer.consumer_tag.should_not be_nil
      cancel_ok = consumer.cancel
      # puts cancel_ok.inspect
      # cancel_ok.consumer_tag.should == consumer.consumer_tag

      ch.close
    end
    t.abort_on_exception = true
    sleep 0.5

    ch = connection.create_channel
    ch.default_exchange.publish("xyzzy", :routing_key => queue_name)

    sleep 0.7
    delivered_data.should be_empty
  end
end
