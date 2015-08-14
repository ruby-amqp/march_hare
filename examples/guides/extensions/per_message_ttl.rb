#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

puts "=> Demonstrating per-message TTL"
puts

conn = MarchHare.connect

ch   = conn.create_channel
x    = ch.fanout("amq.fanout")
q    = ch.queue("", :exclusive => true).bind(x)

10.times do |i|
  x.publish("Message #{i}", :properties => {:expiration => 1000})
end

sleep 0.7
_, content1 = q.pop
puts "Fetched #{content1.inspect} after 0.7 second"

sleep 0.8
_, content2 = q.pop
msg = if content2
        content2.inspect
      else
        "nothing"
      end
puts "Fetched #{msg} after 1.5 second"

sleep 0.7
puts "Closing..."
conn.close
