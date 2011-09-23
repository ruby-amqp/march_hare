require "spec_helper"


describe "Client-defined queue" do

  #
  # Environment
  #

  let(:connection) { HotBunnies.connect }
  let(:channel)    { connection.create_channel }

  after :each do
    channel.close
    connection.close
  end


  it "can be deleted" do
    queue    = channel.queue("", :auto_delete => true)
    queue.delete
  end
end
