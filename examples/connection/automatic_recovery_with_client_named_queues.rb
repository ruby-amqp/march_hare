#!/usr/bin/env ruby
# encoding: utf-8

require "bundler"
Bundler.setup

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'hot_bunnies'

conn = HotBunnies.connect(:heartbeat_interval => 8)

ch0 = conn.create_channel
ch1 = conn.create_channel
ch2 = conn.create_channel
ch3 = conn.create_channel

x   = ch1.topic("hb.examples.recovery.topic", :durable => false)
q1  = ch1.queue("hb.examples.recovery.client_named_queue1", :durable => false)
q2  = ch2.queue("hb.examples.recovery.client_named_queue2", :durable => false)
q3  = ch3.queue("hb.examples.recovery.client_named_queue3", :durable => false)

q1.bind(x, :routing_key => "abc")
q2.bind(x, :routing_key => "def")
q3.bind(x, :routing_key => "xyz")

q1.subscribe do |metadata, payload|
  puts "Consumed #{payload} from Q1 on channel #{q1.channel.id}"
end

q2.subscribe do |metadata, payload|
  puts "Consumed #{payload} from Q2 on channel #{q2.channel.id}"
end

q3.subscribe do |metadata, payload|
  puts "Consumed #{payload} from Q3 (consumer 1, channel #{q3.channel.id})"
end

q3.subscribe do |metadata, payload|
  puts "Consumed #{payload} from Q3 (consumer 2, channel #{q3.channel.id})"
end

loop do
  sleep 1
  data = rand.to_s
  rk   = ["abc", "def", "xyz", Time.now.to_i.to_s].sample

  begin
    x.publish(rand.to_s, :routing_key => rk)
    puts "Published #{data}, routing key: #{rk} on channel #{x.channel.id}"
  # happens when a message is published before the connection
  # is recovered
  rescue Exception, java.lang.Throwable => e
    puts "Exception: #{e.message}"
    # e.backtrace.each do |line|
    #   puts "\t#{line}"
    # end
  end
end
