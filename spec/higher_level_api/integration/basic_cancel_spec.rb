require "spec_helper"

describe 'A consumer' do
  let(:connection) { HotBunnies.connect }

  after :each do
    connection.close
  end

  context "that does not block the caller" do
    it 'receives messages until cancelled' do
      x  = connection.create_channel.default_exchange
      q  = connection.create_channel.queue("", :exclusive => true)

      messages        = []
      consumer_exited = false
      consumer        = nil

      consumer_thread = Thread.new do
        consumer = q.subscribe do |headers, message|
          messages << message
          sleep 0.1
        end
        consumer_exited = true
      end

      publisher_thread = Thread.new do
        20.times do
          x.publish('hello world', :routing_key => q.name)
        end
      end

      sleep 0.2

      consumer.cancel

      consumer_thread.join
      publisher_thread.join

      messages.should_not be_empty
      consumer_exited.should be_true
    end
  end

  context "that DOES block the caller" do
    it 'receives messages until cancelled' do
      x  = connection.create_channel.default_exchange
      q  = connection.create_channel.queue("", :exclusive => true)

      messages        = []
      consumer_exited = false
      consumer        = nil

      consumer_thread = Thread.new do
        consumer = q.build_consumer do |headers, message|
          messages << message
          sleep 0.1
        end
        q.subscribe_with(consumer, :block => true)
        consumer_exited = true
      end

      publisher_thread = Thread.new do
        20.times do
          x.publish('hello world', :routing_key => q.name)
        end
      end

      sleep 0.5

      consumer.cancel

      consumer_thread.join
      publisher_thread.join

      messages.should_not be_empty
      consumer_exited.should be_true
    end
  end


  context "that DOES block the caller and never receives any messages" do
    it 'can be cancelled' do
      x  = connection.create_channel.default_exchange
      q  = connection.create_channel.queue("", :exclusive => true)

      consumer_exited = false
      consumer        = nil

      consumer_thread = Thread.new do
        co       = q.build_consumer(:block => true) do |headers, message|
          messages << message
          sleep 0.1
        end

        consumer = co
        q.subscribe_with(co, :block => true)
        consumer_exited = true
      end

      sleep 1.0

      consumer.cancel

      consumer_thread.join
      consumer_exited.should be_true
    end
  end
end
