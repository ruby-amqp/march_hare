require "spec_helper"
require "rabbitmq/http/client"

describe "Connection recovery" do
  let(:connection)  {  }
  let(:http_client) { RabbitMQ::HTTP::Client.new("http://127.0.0.1:15672") }

  def close_all_connections!
    http_client.list_connections.each do |conn_info|
      http_client.close_connection(conn_info.name)
    end
  end

  def wait_for_recovery
    sleep 0.5
  end

  def with_open(c = MarchHare.connect(:network_recovery_interval => 0.2), &block)
    begin
      block.call(c)
    ensure
      c.close
    end
  end

  def ensure_queue_recovery(ch, q)
    q.purge
    x = ch.default_exchange
    x.publish("msg", :routing_key => q.name)
    sleep 0.2
    q.message_count.should == 1
    q.purge
  end

  #
  # Examples
  #

  it "reconnects after grace period" do
    with_open do |c|
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      c.should be_open
    end
  end

  it "recovers channel" do
    with_open do |c|
      ch1 = c.create_channel
      ch2 = c.create_channel
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      ch1.should be_open
      ch2.should be_open
    end
  end

  it "recovers basic.qos prefetch setting" do
    with_open do |c|
      ch = c.create_channel
      ch.prefetch = 11
      ch.prefetch.should == 11
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      ch.should be_open
      ch.prefetch.should == 11
    end
  end


  it "recovers publisher confirms setting" do
    with_open do |c|
      ch = c.create_channel
      ch.confirm_select
      ch.should be_using_publisher_confirms
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      ch.should be_open
      ch.should be_using_publisher_confirms
    end
  end

  it "recovers transactionality setting" do
    with_open do |c|
      ch = c.create_channel
      ch.tx_select
      ch.should be_using_tx
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      ch.should be_open
      ch.should be_using_tx
    end
  end

  it "recovers client queues" do
    with_open do |c|
      ch = c.create_channel
      q  = ch.queue("bunny.tests.recovery.client-named#{rand}", :exclusive => true)
      close_all_connections!
      sleep 0.1
      c.should_not be_open

      wait_for_recovery
      ch.should be_open
      ensure_queue_recovery(ch, q)
    end
  end
end
