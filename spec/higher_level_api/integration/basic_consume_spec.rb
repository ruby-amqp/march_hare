require "spec_helper"


describe "A consumer" do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end

  it "provides predicates" do
    ch       = connection.create_channel
    q        = ch.queue("", :exclusive => true)

    consumer = q.subscribe(:blocking => false) { |_, _| nil }

    # consumer tag will be sent by the broker, so this happens
    # asynchronously and we can either add callbacks/use latches or
    # just wait. MK.
    sleep(1.0)
    consumer.should be_active

    consumer.cancel
    sleep(1.0)
    consumer.should_not be_active
    consumer.should be_cancelled
  end
end


describe "Multiple non-exclusive consumers per queue" do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end

  context "on the same channel (so prefetch levels won't affect message distribution)" do
    it "have messages distributed to them in the round robin manner" do
      ch = connection.create_channel

      n                = 100
      mailbox1         = []
      mailbox2         = []
      mailbox3         = []

      all_received     = java.util.concurrent.CountDownLatch.new(n)
      consumer_channel = connection.create_channel

      q                = ch.queue("", :exclusive => true)

      consumer1        = q.subscribe(:blocking => false) do |metadata, payload|
        mailbox1 << payload
        all_received.count_down
      end
      consumer2        = q.subscribe(:blocking => false) do |metadata, payload|
        mailbox2 << payload
        all_received.count_down
      end
      consumer3        = q.subscribe(:blocking => false) do |metadata, payload|
        mailbox3 << payload
        all_received.count_down
      end


      sleep 1.0 # let consumers in other threads start.
      n.times do |i|
        ch.default_exchange.publish("Message #{i}", :routing_key => q.name)
      end

      all_received.await

      mailbox1.size.should >= 33
      mailbox2.size.should >= 33
      mailbox3.size.should >= 33

      consumer1.cancel
      consumer2.cancel
      consumer3.cancel
    end
  end
end


describe "A consumer" do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end

  context "instantiated manually" do
    it "works just like HotBunnies::Queue#subscribe" do
      ch = connection.create_channel

      n                = 100
      mailbox1         = []
      mailbox2         = []
      mailbox3         = []

      all_received     = java.util.concurrent.CountDownLatch.new(n)
      consumer_channel = connection.create_channel

      q                = ch.queue("", :exclusive => true)

      fn               = lambda do |metadata, payload|
        mailbox1 << payload
        all_received.count_down
      end
      consumer_object  = q.build_consumer(:blocking => false, &fn)

      consumer1        = q.subscribe_with(consumer_object, :blocking => false)
      consumer2        = q.subscribe(:blocking => false) do |metadata, payload|
        mailbox2 << payload
        all_received.count_down
      end
      consumer3        = q.subscribe(:blocking => false) do |metadata, payload|
        mailbox3 << payload
        all_received.count_down
      end


      sleep 1.0 # let consumers in other threads start.
      n.times do |i|
        ch.default_exchange.publish("Message #{i}", :routing_key => q.name)
      end

      all_received.await

      mailbox1.size.should >= 33
      mailbox2.size.should >= 33
      mailbox3.size.should >= 33

      consumer1.cancel
      consumer2.cancel
      consumer3.cancel
    end
  end
end
