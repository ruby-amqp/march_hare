require "spec_helper"

RSpec.describe "A channel" do

  #
  # Environment
  #

  let(:connection) { MarchHare.connect }

  after :each do
    connection.close
  end

  #
  # Examples
  #

  context "when closed" do
    it "releases the id" do
      ch = connection.create_channel
      n = ch.number

      expect(ch).to be_open
      ch.close
      expect(ch).to be_closed

      # a new channel with the same id can be created
      ch2 = connection.create_channel(n)
      ch2.close
    end
  end

  context "when instructed to cancel consumers before closing" do
    it "releases the id" do
      ch = connection.create_channel.configure do |new_ch|
        new_ch.cancel_consumers_before_closing!
      end
      n = ch.number

      10.times do |i|
        q = ch.temporary_queue()
        q.subscribe(manual_ack: true) do |delivery_info, properties, payload|
          # a no-op
        end
      end

      expect(ch).to be_open
      ch.close
      expect(ch).to be_closed

      # a new channel with the same id can be created
      ch2 = connection.create_channel(n)
      ch2.close
    end
  end
end
