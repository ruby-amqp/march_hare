RSpec.describe "Direct exchange" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can be declared" do
    exchange = channel.exchange("march.hare.exchanges.direct1", :type => :direct)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange, :routing_key => "abc")

    exchange.publish("", :routing_key => "xyz")
    exchange.publish("", :routing_key => "abc")

    sleep(0.3)

    mc, _cc = queue.status
    expect(mc).to eq(1)
  end
end



RSpec.describe "Fanout exchange" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can be declared" do
    exchange = channel.exchange("march.hare.exchanges.fanout1", :type => :fanout)
    expect(exchange).not_to be_internal
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange)

    exchange.publish("")
    exchange.publish("", :routing_key => "xyz")
    exchange.publish("", :routing_key => "abc")

    sleep(0.5)

    mc, _cc = queue.status
    expect(mc).to eq(3)
  end
end



RSpec.describe "Topic exchange" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can be declared" do
    exchange = channel.exchange("march.hare.exchanges.topic1", :type => :topic)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange, :routing_key => "log.*")

    exchange.publish("")
    exchange.publish("", :routing_key => "accounts.signup")
    exchange.publish("", :routing_key => "log.info")
    exchange.publish("", :routing_key => "log.warn")

    sleep(0.5)

    mc, _cc = queue.status
    expect(mc).to eq(2)
  end
end



RSpec.describe "Headers exchange" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can be declared" do
    exchange = channel.exchange("march.hare.exchanges.headers1", :type => :headers)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange, :arguments => { 'x-match' => 'all', 'arch' => "x86_64", 'os' => "linux" })

    exchange.publish "For linux/IA64",   :properties => { :headers => { 'arch' => "x86_64", 'os' => 'linux' } }
    exchange.publish "For linux/x86",    :properties => { :headers => { 'arch' => "x86",  'os' => 'linux' } }
    exchange.publish "For any linux",    :properties => { :headers => { 'os' => 'linux' } }
    exchange.publish "For OS X",         :properties => { :headers => { 'os' => 'macosx' } }
    exchange.publish "For solaris/IA64", :properties => { :headers => { 'os' => 'solaris', 'arch' => 'x86_64' } }

    sleep(0.3)

    mc, _cc = queue.status
    expect(mc).to eq(1)
  end
end



RSpec.describe "Internal exchange" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can be declared" do
    exchange = channel.topic("march.hare.exchanges.topic.internal", :internal => true)
    expect(exchange).to be_internal

    exchange.delete
  end
end
