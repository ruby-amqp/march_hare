require "spec_helper"

describe HotBunnies::Exchange do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "should declare a direct exchange with default attributes" do
    channel.exchange("hot_bunnies.spec.exchanges.direct01", :type => :direct) do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "should declare an auto-deleted direct exchange" do
    channel.exchange("hot_bunnies.spec.exchanges.direct02", :type => :direct, :auto_delete => true) do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "should declare an durable direct exchange" do
    channel.exchange("hot_bunnies.spec.exchanges.direct03", :type => :direct, :durable => true) do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "should declare a fanout exchange with default attributes" do
    channel.exchange("hot_bunnies.spec.exchanges.fanout01") do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "should declare a direct exchange auto-deleted fanout exchange" do
    channel.exchange("hot_bunnies.spec.exchanges.fanout02", :auto_delete => true) do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "should declare a direct exchange durable fanout exchange" do
    channel.exchange("hot_bunnies.spec.exchanges.fanout03", :durable => true) do
      |exchange, declare_ok|
      declare_ok.java_kind_of?(HotBunnies::AMQP::Exchange::DeclareOk).should be_true
    end
  end

  it "shuold delete fresh declared exchange" do
    channel.exchange("hot_bunnies.spec.exchanges.direct01", :type => :direct).
      delete().java_kind_of?(HotBunnies::AMQP::Exchange::DeleteOk).should be_true
  end

  it "should bind two exchanges" do
    source =       channel.exchange("hot_bunnies.spec.exchanges.source", :auto_delete => true)
    destianation = channel.exchange("hot_bunnies.spec.exchanges.destination", :auto_delete => true)

    queue = channel.queue("", :auto_delete => true)
    queue.bind(destianation)

    channel.exchange_bind(destianation.name, source.name, "")

    source.publish("")
    queue.get.should_not be_nil
  end
end
