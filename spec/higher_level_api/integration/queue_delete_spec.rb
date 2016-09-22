describe "Queue" do

  #
  # Environment
  #

  let(:connection) { MarchHare.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end


  context "that exists" do
    it "can be deleted" do
      q    = channel.queue("")
      q.delete
    end
  end

  context "that DOES NOT exist" do
    it "raises NO exception (as of RabbitMQ 3.2)" do
      ch = connection.create_channel
      q  = ch.queue("")

      q.delete(true, true)
      # No exception as of RabbitMQ 3.2. MK.
      q.delete(true, true)
    end
  end
end
