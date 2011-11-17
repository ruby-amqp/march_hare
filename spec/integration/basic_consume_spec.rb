require "spec_helper"

describe "Queue consumer" do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "provides predicates" do
    queue        = channel.queue("", :auto_delete => true)

    subscription = queue.subscribe(:blocking => false) { |_, _| nil }

    # consumer tag will be sent by the broker, so this happens
    # asynchronously and we can either add callbacks/use latches or
    # just wait. MK.
    sleep(1.0)
    subscription.should be_active

    subscription.cancel
    sleep(1.0)
    subscription.should_not be_active

    subscription.shutdown!
  end
end
