RSpec.describe "Queue" do
  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end

  it "cannot be created using a symbol as name" do
    expect {
      channel.queue(:not_valid_name)
    }.to raise_error(ArgumentError)
  end

  context "with a server-generated name" do
    it "can be declared as auto-deleted" do
      q = channel.queue("", :auto_delete => true)
      expect(q).to be_auto_delete
      q.delete
    end

    it "can be declared as auto-deleted and non-durable" do
      q = channel.queue("", :auto_delete => true, :durable => false)
      expect(q).to be_auto_delete
      expect(q).not_to be_durable
      q.delete
    end

    it "can be declared as NON-auto-deleted" do
      q = channel.queue("", :auto_delete => false)
      expect(q).not_to be_auto_delete
      expect(q).not_to be_durable
      q.delete
    end

    it "can be declared as NON-durable" do
      q = channel.queue("", :durable => false)
      expect(q).not_to be_durable
      q.delete
    end

    it "can be declared with additional attributes like x-message-ttle" do
      q = channel.queue("", :durable => false, :arguments => { 'x-message-ttl' => 2000 })
      x = channel.exchange("", :type => :direct)

      100.times do |i|
        x.publish("Message #{i}", :routing_key => q.name)
      end

      expect(q.get).not_to be_nil
      sleep(2.1)

      expect(q.get).to be_nil
      q.delete
    end
  end

  context "declared as temporary" do
    it "is declared as exclusive" do
      q = channel.temporary_queue()
      expect(q).to be_exclusive
      expect(q).not_to be_durable
      q.delete
    end
  end

  context "declared as durable" do
    it "is declared as such" do
      q = channel.durable_queue("bunny.durable.123")
      expect(q).to be_durable
      expect(q).not_to be_exclusive
      q.delete
    end
  end

  context "declared as quorum" do
    it "is declared as durable and non-exclusive" do
      q = channel.quorum_queue("bunny.qq.1", arguments: {
        "x-quorum-initial-group-size" => 3
      })
      expect(q).to be_durable
      expect(q).not_to be_exclusive
      q.delete
    end
  end

  context "declared as stream" do
    it "is declared as durable and non-exclusive" do
      q = channel.stream("bunny.sq.1", arguments: {
        "x-max-length-bytes"              => 20_000_000_000,
        "x-stream-max-segment-size-bytes" => 100_000_000      })
      expect(q).to be_durable
      expect(q).not_to be_exclusive
      q.delete
    end
  end
end
