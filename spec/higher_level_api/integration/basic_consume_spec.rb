RSpec.describe "A consumer" do
  let(:connection) { MarchHare.connect }

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
    expect(consumer).to be_active

    consumer.cancel
    sleep(1.0)
    expect(consumer).not_to be_active
    expect(consumer).to be_cancelled
  end

  it "has a consumer_tag" do
    ch       = connection.create_channel
    q        = ch.queue("", :exclusive => true)

    consumer1 = q.subscribe(:blocking => false) { |_, _| nil }

    sleep(1.0)
    expect(consumer1.consumer_tag).to match(/^amq.ctag/)
    consumer1.cancel

    custom_consumer_tag = "unique_consumer_tag_#{rand(1_000)}"
    consumer2 = q.subscribe(:consumer_tag => custom_consumer_tag, :blocking => false) { |_, _| nil }

    expect(consumer2.consumer_tag).to eq(custom_consumer_tag)

    consumer2.cancel
  end
end


RSpec.describe "Multiple non-exclusive consumers per queue" do
  let(:connection) { MarchHare.connect }

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

      all_received = java.util.concurrent.CountDownLatch.new(n)
      consumer_ch  = connection.create_channel

      q                = consumer_ch.queue("", :exclusive => true)

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

      all_received.await(10, java.util.concurrent.TimeUnit::SECONDS)

      expect(mailbox1.size).to be >= 33
      expect(mailbox2.size).to be >= 33
      expect(mailbox3.size).to be >= 33

      consumer1.cancel
      consumer2.cancel
      consumer3.cancel
    end
  end
end

RSpec.describe "A consumer" do
  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end

  context "instantiated manually" do
    it "works just like MarchHare::Queue#subscribe" do
      ch = connection.create_channel

      n                = 100
      mailbox1         = []
      mailbox2         = []
      mailbox3         = []

      all_received = java.util.concurrent.CountDownLatch.new(n)
      consumer_ch  = connection.create_channel

      q                = consumer_ch.queue("", :exclusive => true)

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

      all_received.await(10, java.util.concurrent.TimeUnit::SECONDS)

      expect(mailbox1.size).to be >= 33
      expect(mailbox2.size).to be >= 33
      expect(mailbox3.size).to be >= 33

      consumer1.cancel
      consumer2.cancel
      consumer3.cancel
    end
  end

  describe "header consumption" do
    let(:connection) { MarchHare.connect }
    let(:channel)    { connection.create_channel }

    it "should convert long headers" do
        queue    = channel.temporary_queue()
        sleep(1)

        expected_short = "short"
        expected_long = "l"*512
        expected_complex = "c"*1024
        queue.publish("hello", :headers => {
          :long => expected_long,
          :short => expected_short,
          :complex => {:foo => [{:bar => expected_complex}]}
        })
        delivery = nil
        latch = java.util.concurrent.CountDownLatch.new(1)

        queue.subscribe do |metadata, message|
          delivery = {:metadata => metadata, :message => message}
          latch.count_down
        end

        latch.await(10, java.util.concurrent.TimeUnit::SECONDS)

        headers = delivery[:metadata].headers
        expect(headers["short"]).to eq(expected_short)
        expect(headers["long"]).to eq(expected_long)
        expect(headers["complex"]["foo"][0]["bar"]).to eq(expected_complex)
      end
  end
end
