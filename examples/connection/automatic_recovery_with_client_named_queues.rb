#!/usr/bin/env ruby
# encoding: utf-8

require "bundler"
Bundler.setup

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'hot_bunnies'

conn = HotBunnies.connect(:heartbeat_interval => 8)

ch = conn.create_channel
x  = ch.topic("hb.examples.recovery.topic", :durable => false)
q  = ch.queue("hb.examples.recovery.client_named_queue1", :durable => false)

q.bind(x, :routing_key => "abc").bind(x, :routing_key => "def")

q.subscribe do |metadata, payload|
  puts "Consumed #{payload}"
end

loop do
  sleep 2
  data = rand.to_s
  rk   = ["abc", "def"].sample

  begin
    x.publish(rand.to_s, :routing_key => rk)
    puts "Published #{data}, routing key: #{rk}"
  # happens when a message is published before the connection
  # is recovered
  rescue Exception => e
    puts "Exception: #{e.message}"
    e.backtrace.each do |line|
      puts "\t#{line}"
    end
  end
end
