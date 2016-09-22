RSpec.describe "Non-blocking consumer" do
  let(:connection) do
    MarchHare.connect
  end

  after :each do
    connection.close if connection.open?
  end

  let(:queue_name) { "basic.consume#{rand}" }

  it "supports consumer cancellation notifications" do
    cancelled = false

    ch = connection.create_channel
    ch2 = connection.create_channel
    q   = ch2.queue(queue_name, :auto_delete => true)

    q.subscribe(:on_cancellation => Proc.new { |_ch, consumer| cancelled = true }) do |_, _|
      # no-op
    end

    sleep 0.5
    x = ch.default_exchange
    x.publish("abc", :routing_key => queue_name)

    sleep 0.5
    ch.queue(queue_name, :auto_delete => true).delete

    sleep 0.5
    expect(cancelled).to eq(true)

    ch.close
  end
end


RSpec.describe "Blocking consumer" do
  let(:connection) do
    MarchHare.connect
  end

  after :each do
    connection.close if connection.open?
  end

  let(:queue_name) { "basic.consume#{rand}" }

  it "supports consumer cancellation notifications" do
    cancelled = false

    ch = connection.create_channel
    t  = Thread.new do
      ch2 = connection.create_channel
      q   = ch2.queue(queue_name, :auto_delete => true)

      q.subscribe(:on_cancellation => Proc.new { |_ch, consumer| cancelled = true }, :block => true) do |_, _|
        # no-op
      end
    end
    t.abort_on_exception = true

    sleep 0.5
    x = ch.default_exchange
    x.publish("abc", :routing_key => queue_name)

    sleep 0.5
    ch.queue(queue_name, :auto_delete => true).delete

    sleep 0.5
    expect(cancelled).to eq(true)

    t.kill
    ch.close
  end
end
