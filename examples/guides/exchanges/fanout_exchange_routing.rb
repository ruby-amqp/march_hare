#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

puts "=> Fanout exchange routing"
puts

conn = MarchHare.connect

ch   = conn.create_channel
x    = ch.fanout("examples.pings")

10.times do |i|
  q = ch.queue("", :auto_delete => true).bind(x)
  q.subscribe do |delivery_info, properties, payload|
    puts "[consumer] #{q.name} received a message: #{payload}"
  end
end

x.publish("Ping")

sleep 0.5
x.delete
puts "Disconnecting..."
conn.close
