require "spec_helper"

describe "A consumer" do
  let(:connection) { CarrotCake.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can access message metadata (both message properties and delivery information)" do
    latch    = java.util.concurrent.CountDownLatch.new(1)
    queue    = channel.queue("", :exclusive => true)
    exchange = channel.exchange("amq.fanout", :type => :fanout)

    queue.bind(exchange, :routing_key => "hotbunnies.key")

    @now     = Time.now
    @payload = "Hello, world!"
    @meta    = nil

    consumer = queue.subscribe(:blocking => false) do |metadata, payload|
      begin
        # we will run assertions on the main thread because RSpec uses exceptions
        # for its purposes every once in a while. MK.
        @meta = metadata
      rescue Exception => e
        e.print_stack_trace
      ensure
        latch.count_down
      end
    end

    exchange.publish(@payload,
                     :properties => {
                       :app_id      => "hotbunnies.tests",
                       :persistent  => true,
                       :priority    => 8,
                       :type        => "kinda.checkin",
                       # headers table keys can be anything
                       :headers     => {
                         "coordinates" => {
                           "latitude"  => 59.35,
                           "longitude" => 18.066667
                         },
                         "time"         => @now,
                         "participants" => 11,
                         "venue"        => "Stockholm",
                         "true_field"   => true,
                         "false_field"  => false,
                         "nil_field"    => nil,
                         "ary_field"    => ["one", 2.0, 3, [{ "abc" => 123 }]]
                       },
                       :timestamp        => @now,
                       :reply_to         => "a.sender",
                       :correlation_id   => "r-1",
                       :message_id       => "m-1",
                       :content_type     => "application/octet-stream",
                       # just an example. MK.
                       :content_encoding => "zip/zap"
                     },
                     :routing_key    => "hotbunnies.key")
    latch.await

    @meta.routing_key.should  == "hotbunnies.key"
    @meta.content_type.should == "application/octet-stream"
    @meta.content_encoding.should == "zip/zap"
    @meta.priority.should == 8

    time = Time.at(@meta.headers["time"].getTime/1000)
    time.to_i.should == @now.to_i

    @meta.headers["coordinates"]["latitude"].should    == 59.35
    @meta.headers["participants"].should == 11
    @meta.headers["true_field"].should == true
    @meta.headers["false_field"].should == false
    @meta.headers["nil_field"].should be_nil

    @meta.timestamp.should == Time.at(@now.to_i)
    @meta.type.should == "kinda.checkin"
    @meta.consumer_tag.should_not be_nil
    @meta.consumer_tag.should_not be_empty
    @meta.delivery_tag.to_i.should == 1
    @meta.delivery_mode.should == 2
    @meta.should be_persistent
    @meta.reply_to.should == "a.sender"
    @meta.correlation_id.should == "r-1"
    @meta.message_id.should == "m-1"
    @meta.should_not be_redelivered

    @meta.app_id.should == "hotbunnies.tests"
    @meta.exchange.should == "amq.fanout"
  end
end
