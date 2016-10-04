RSpec.describe MarchHare::Exchange do
  let(:connection) { MarchHare.connect }

  after do
    connection.close
  end

  it 'allows a message timestamp to be included when publishing a message' do
    ch = connection.create_channel
    ch.confirm_select
    queue = ch.queue('publish_spec', exclusive: true)
    timestamp = Time.new(2016)

    ch.default_exchange.publish(
      'hello, world!',
      routing_key: queue.name,
      properties: {timestamp: timestamp},
    )

    expect(ch.wait_for_confirms).to be_truthy
    expect(queue.get.first.properties.timestamp).to eq timestamp.to_java
  end
end
