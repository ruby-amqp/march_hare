require "spec_helper"


describe "Queue" do

  #
  # Environment
  #

  let(:connection) { CarrotCake.connect }
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
    it "cannot be deleted" do
      ch = connection.create_channel
      q  = ch.queue("")

      q.delete(true, true)
      lambda do
        q.delete(true, true)
      end.should raise_error(CarrotCake::NotFound)
    end
  end
end
