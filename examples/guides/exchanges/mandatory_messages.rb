#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "hot_bunnies"

puts "=> Publishing messages as mandatory"
puts

conn = HotBunnies.connect

ch   = conn.create_channel
x    = ch.default_exchange

ch.on_return do |reply_code, reply_text, exchange, routing_key, basic_properties, payload|
  puts "Got a returned message: #{payload}, reply: #{reply_code} #{reply_text}"
end

q = ch.queue("", :exclusive => true)
q.subscribe do |metadata, payload|
  puts "Consumed a message: #{payload}"
end

x.publish("This will NOT be returned", :mandatory => true, :routing_key => q.name)
x.publish("This will be returned", :mandatory => true, :routing_key => "akjhdfkjsh#{rand}")

sleep 1.0
puts "Disconnecting..."
conn.close
