require "spec_helper"


describe 'A consumer of a queue' do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it 'receives messages until cancelled' do
    exchange = connection.create_channel.default_exchange
    queue = connection.create_channel.queue("", :auto_delete => true)
    subscription = queue.subscribe

    messages = []
    consumer_exited = false

    consumer_thread = Thread.new do
      subscription.each do |headers, message|
        messages << message
        sleep 0.1
      end
      consumer_exited = true
    end

    publisher_thread = Thread.new do
      20.times do
        exchange.publish('hello world', :routing_key => queue.name)
        sleep 0.01
      end
    end

    sleep 0.2

    subscription.cancel

    consumer_thread.join
    publisher_thread.join

    messages.should_not be_empty
    consumer_exited.should be_true
  end
end

describe "Multiple non-exclusive consumers per queue" do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  context "on the same channel (so prefetch levels won't affect message distribution)" do
    it "have messages distributed to them in the round robin manner" do
      n                = 100
      mailbox1         = []
      mailbox2         = []
      mailbox3         = []

      all_received     = java.util.concurrent.CountDownLatch.new(n)
      consumer_channel = connection.create_channel

      queue            = channel.queue("", :auto_delete => true)

      consumer1        = queue.subscribe(:blocking => false) do |metadata, payload|
        mailbox1 << payload
        all_received.count_down
      end
      consumer2        = queue.subscribe(:blocking => false) do |metadata, payload|
        mailbox2 << payload
        all_received.count_down
      end
      consumer3        = queue.subscribe(:blocking => false) do |metadata, payload|
        mailbox3 << payload
        all_received.count_down
      end


      sleep 2.0 # let consumers in other threads start.
      n.times do |i|
        channel.default_exchange.publish("Message #{i}", :routing_key => queue.name)
      end

      all_received.await

      mailbox1.size.should >= 33
      mailbox2.size.should >= 33
      mailbox3.size.should >= 33

      consumer1.shutdown!
      consumer2.shutdown!
      consumer3.shutdown!
    end
  end
end


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
