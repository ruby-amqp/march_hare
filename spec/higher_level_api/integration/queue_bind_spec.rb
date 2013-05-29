require "spec_helper"


describe "A queue" do

  #
  # Environment
  #

  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end


  #
  # Examples
  #

  it "can be bound to amq.fanout" do
    ch = connection.create_channel
    x  = ch.exchange("amq.fanout", :type => :fanout, :durable => true, :auto_delete => false)
    q  = ch.queue("", :auto_delete => true)
    x.publish("")
    q.get.should be_nil

    q.bind(x)

    x.publish("", :routing_key => q.name)
    q.get.should_not be_nil
  end


  it "can be bound to a newly declared exchange" do
    ch = connection.create_channel
    x  = ch.exchange("hot.bunnies.fanout", :type => :fanout, :durable => false, :auto_delete => true)
    q  = ch.queue("", :auto_delete => true)
    x.publish("")
    q.get.should be_nil

    q.bind(x)

    x.publish("", :routing_key => q.name)
    q.get.should_not be_nil
  end


  it "is automatically bound to the default exchange" do
    ch = connection.create_channel
    x  = ch.default_exchange
    q  = ch.queue("", :auto_delete => true)

    x.publish("", :routing_key => q.name)
    q.get.should_not be_nil
  end

  context "when the exchange does not exist" do
    it "raises an exception" do
      ch = connection.create_channel
      q  = ch.queue("", :auto_delete => true)

      raised = nil
      begin
        q.bind("asyd8a9d98sa73t78hd9as^&&(&@#(*^")
      rescue HotBunnies::NotFound => e
        raised = e
      end

      raised.channel_close.reply_text.should =~ /no exchange/
    end
  end
end
