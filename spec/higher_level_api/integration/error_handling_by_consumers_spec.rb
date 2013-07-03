require "spec_helper"

describe "A consumer that catches exceptions" do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "stays up" do
    mailbox  = []
    exchange = channel.exchange("hot_bunnies.exchanges.fanout#{Time.now.to_i}", :type => :fanout, :auto_delete => true)
    queue    = channel.queue("", :exclusive => true)

    queue.bind(exchange)
    consumer = queue.subscribe(:blocking => false) do |meta, payload|
      n = meta.properties.headers['X-Number']

      begin
        if n.odd?
          raise "A failure"
        else
          mailbox << payload
        end
      rescue Exception => e
        # no-op
      end
    end

    25.times do |i|
      exchange.publish("Message ##{i}", :routing_key => "xyz", :properties => {
                         :headers => {
                           'X-Number' => i
                         }
                       })
    end

    sleep(0.5)

    mc, cc = queue.status
    mc.should == 0

    mailbox.size.should == 13
    consumer.shutdown!
  end
end




describe "A consumer that DOES NOT catch exceptions" do
  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "becomes inactive when the channels prefetch is filled with unacked messages" do
    mailbox  = []
    exchange = channel.exchange("hot_bunnies.exchanges.fanout#{Time.now.to_i}#{rand}", :type => :fanout, :auto_delete => true)
    queue    = channel.queue("", :exclusive => true)

    channel.prefetch = 5

    queue.bind(exchange)
    consumer = queue.subscribe(:blocking => false, :ack => true) do |meta, payload|
      n = meta.properties.headers['X-Number']

      if n.odd?
        raise "A failure"
      else
        mailbox << payload
        meta.ack
      end
    end

    25.times do |i|
      exchange.publish("Message ##{i}", :routing_key => "xyz", :properties => {
                         :headers => {
                           'X-Number' => i
                         }
                       })
    end

    sleep(0.5)

    message_count, _ = queue.status
    message_count.should == 15

    mailbox.size.should == 5
    consumer.shutdown!
  end
end
