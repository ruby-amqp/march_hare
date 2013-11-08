#!/usr/bin/env ruby
require 'march_hare'

connection = MarchHare.connect

connection.on_blocked do |reason|
  puts "I am blocked now. Reason: #{reason}"
end
connection.on_unblocked do |_|
  puts "I am unblocked now."
end

ch = connection.create_channel
x  = ch.default_exchange

10.times do |i|
  x.publish("")
end

sleep 5.0

10.times do |i|
  x.publish("")
end

sleep 30.0

connection.close
