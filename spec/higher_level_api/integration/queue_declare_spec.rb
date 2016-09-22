describe "Queue" do
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
end
