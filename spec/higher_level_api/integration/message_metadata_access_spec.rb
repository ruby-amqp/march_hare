RSpec.describe "A consumer" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "can access message metadata (both message properties and delivery information)" do
    latch    = java.util.concurrent.CountDownLatch.new(1)
    queue    = channel.queue("", :exclusive => true)
    exchange = channel.exchange("amq.fanout", :type => :fanout)

    queue.bind(exchange, :routing_key => "march.hare.key")

    @now     = Time.now
    @payload = "Hello, world!"
    @meta    = nil

    _ = queue.subscribe(:blocking => false) do |metadata, payload|
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
                       :app_id      => "march.hare.tests",
                       :persistent  => true,
                       :priority    => 8,
                       :type        => "kinda.checkin",
                       # headers table keys can be anything
                       :headers     => {
                         :coordinates => {
                           :latitude  => 59.35,
                           "longitude" => 18.066667
                         },
                         "time"         => @now,
                         "participants" => 11,
                         :venue         => "Stockholm",
                         "true_field"   => true,
                         "false_field"  => false,
                         "nil_field"    => nil,
                         "ary_field"    => ["one", 2.0, 3, [{ :abc => 123 }]]
                       },
                       :timestamp        => @now,
                       :reply_to         => "a.sender",
                       :correlation_id   => "r-1",
                       :message_id       => "m-1",
                       :content_type     => "application/octet-stream",
                       # just an example. MK.
                       :content_encoding => "zip/zap"
                     },
                     :routing_key    => "march.hare.key")
    latch.await

    expect(@meta.routing_key).to eq("march.hare.key")
    expect(@meta.content_type).to eq("application/octet-stream")
    expect(@meta.content_encoding).to eq("zip/zap")
    expect(@meta.priority).to eq(8)

    time = Time.at(@meta.headers["time"].getTime/1000)
    expect(time.to_i).to eq(@now.to_i)

    expect(@meta.headers["coordinates"]["latitude"]).to eq(59.35)
    expect(@meta.headers["participants"]).to eq(11)
    expect(@meta.headers["true_field"]).to eq(true)
    expect(@meta.headers["false_field"]).to eq(false)
    expect(@meta.headers["nil_field"]).to be_nil

    expect(@meta.timestamp).to eq(Time.at(@now.to_i))
    expect(@meta.type).to eq("kinda.checkin")
    expect(@meta.consumer_tag).not_to be_nil
    expect(@meta.consumer_tag).not_to be_empty
    expect(@meta.delivery_tag.to_i).to eq(1)
    expect(@meta.delivery_mode).to eq(2)
    expect(@meta).to be_persistent
    expect(@meta.reply_to).to eq("a.sender")
    expect(@meta.correlation_id).to eq("r-1")
    expect(@meta.message_id).to eq("m-1")
    expect(@meta).not_to be_redelivered

    expect(@meta.app_id).to eq("march.hare.tests")
    expect(@meta.exchange).to eq("amq.fanout")
  end

  it "can handle properties being set at the top level" do
    latch    = java.util.concurrent.CountDownLatch.new(1)
    queue    = channel.queue("", :exclusive => true)
    exchange = channel.exchange("amq.fanout", :type => :fanout)

    queue.bind(exchange, :routing_key => "march.hare.key")

    @now     = Time.now
    @payload = "Hello, world!"
    @meta    = nil

    _ = queue.subscribe(:blocking => false) do |metadata, payload|
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
                     :app_id      => "march.hare.tests",
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
                     :content_encoding => "zip/zap",
                     :routing_key    => "march.hare.key")
    latch.await

    expect(@meta.routing_key).to eq("march.hare.key")
    expect(@meta.content_type).to eq("application/octet-stream")
    expect(@meta.content_encoding).to eq("zip/zap")
    expect(@meta.priority).to eq(8)

    time = Time.at(@meta.headers["time"].getTime/1000)
    expect(time.to_i).to eq(@now.to_i)

    expect(@meta.headers["coordinates"]["latitude"]).to eq(59.35)
    expect(@meta.headers["participants"]).to eq(11)
    expect(@meta.headers["true_field"]).to eq(true)
    expect(@meta.headers["false_field"]).to eq(false)
    expect(@meta.headers["nil_field"]).to be_nil

    expect(@meta.timestamp).to eq(Time.at(@now.to_i))
    expect(@meta.type).to eq("kinda.checkin")
    expect(@meta.consumer_tag).not_to be_nil
    expect(@meta.consumer_tag).not_to be_empty
    expect(@meta.delivery_tag.to_i).to eq(1)
    expect(@meta.delivery_mode).to eq(2)
    expect(@meta).to be_persistent
    expect(@meta.reply_to).to eq("a.sender")
    expect(@meta.correlation_id).to eq("r-1")
    expect(@meta.message_id).to eq("m-1")
    expect(@meta).not_to be_redelivered

    expect(@meta.app_id).to eq("march.hare.tests")
    expect(@meta.exchange).to eq("amq.fanout")
  end
end
