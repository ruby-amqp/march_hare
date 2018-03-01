java_import java.util.concurrent.CountDownLatch
java_import java.util.concurrent.TimeUnit

RSpec.describe "MarchHare.connect" do

  #
  # Examples
  #

  it "lets you specify requested heartbeat interval" do
    c = MarchHare.connect(requested_heartbeat: 10)
    c.close
  end

  it "lets you specify connection timeout interval" do
    c = MarchHare.connect(connection_timeout: 3)
    c.close
  end

  context "when connection fails due to unknown host" do
    it "raises an exception" do
      expect {
        MarchHare.connect(hostname: "a8s878787s8d78sd78.lol")
      }.to raise_error(MarchHare::ConnectionRefused)
    end
  end

  context "when connection fails due to RabbitMQ node not running" do
    it "raises an exception" do
      expect {
        MarchHare.connect(hostname: "rubymarchhare.info")
      }.to raise_error(MarchHare::ConnectionRefused)
    end
  end

  context "when connection fails due to invalid credentials" do
    it "raises an exception" do
      expect {
        MarchHare.connect(:username => "this$username%does*not&exist")
      }.to raise_error(MarchHare::PossibleAuthenticationFailureError)
    end
  end

  it "handles amqp:// URIs w/o path part" do
    c = MarchHare.connect(uri: "amqp://127.0.0.1")

    expect(c.vhost).to eq("/")
    expect(c.host).to eq("127.0.0.1")
    expect(c.port).to eq(5672)
    expect(c.ssl?).to eq(false)

    c.close
  end

  it "lets you specify executor (thread pool) factory" do
    calls = 0
    factory = double(:executor_factory)
    allow(factory).to receive(:call) do
      calls += 1
      MarchHare::JavaConcurrent::Executors.new_cached_thread_pool
    end
    c = MarchHare.connect(executor_factory: factory, network_recovery_interval: 0)
    c.close
    c.automatically_recover
    c.close
    expect(calls).to eq(2)
  end


  it "lets you specify fixed thread pool size" do
    c = MarchHare.connect(thread_pool_size: 20, network_recovery_interval: 0)
    expect(c).to be_connected
    c.close
    expect(c).not_to be_connected
    c.automatically_recover
    sleep 0.5
    expect(c).to be_connected
    c.close
  end

  it "lets you specify host and port" do
    expect {
      MarchHare.connect(host: "127.0.0.1", port: 35672, network_recovery_interval: 0)
    }.to raise_error(MarchHare::ConnectionRefused)

    c = MarchHare.connect(host: "127.0.0.1", port: 5672, network_recovery_interval: 0)
    expect(c).to be_connected
    c.close
  end

  it "lets you specify multiple hosts" do
    c = MarchHare.connect(hosts: ["127.0.0.1"], network_recovery_interval: 0)
    expect(c).to be_connected
    c.close
    expect(c).not_to be_connected
    c.automatically_recover
    sleep 0.5
    expect(c).to be_connected
    c.close
  end

  it "lets you specify multiple addresses" do
    c = MarchHare.connect(addresses: ["127.0.0.1:5672", "127.0.0.1"], network_recovery_interval: 0)
    expect(c).to be_connected
    c.close
    expect(c).not_to be_connected
    c.automatically_recover
    sleep 0.5
    expect(c).to be_connected
    c.close
  end

  it "lets you specify thread factory (e.g. for GAE)" do
    class ThreadFactory
      include java.util.concurrent.ThreadFactory

      def newThread(runnable)
        java.lang.Thread.new(runnable)
      end
    end

    c  = MarchHare.connect(thread_factory: ThreadFactory.new)
    expect(c).to be_connected
    ch = c.create_channel
    c.close
  end

  it "lets you specify exception handler" do
    class ExceptionHandler < com.rabbitmq.client.impl.DefaultExceptionHandler
      include com.rabbitmq.client.ExceptionHandler

      def handleConsumerException(ch, ex, consumer, tag, method_name)
        # different from the default in that it does not print
        # anything. MK.
      end
    end

    c  = MarchHare.connect(exception_handler: ExceptionHandler.new)
    ch = c.create_channel
    q  = ch.queue("", exclusive: true)
    q.subscribe do |*args|
      raise "oops"
    end

    x  = ch.default_exchange
    x.publish("", routing_key: q.name)
    sleep 0.5

    c.close
  end
end


RSpec.describe "MarchHare::Session#start" do
  it "is a no-op added for better compatibility with Bunny and to guard non-idempotent AMQConnection#start" do
    c = MarchHare.connect
    100.times do
      c.start
    end

    c.close
  end
end
