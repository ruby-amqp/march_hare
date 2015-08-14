#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

puts "=> Demonstrating queue TTL (queue leases)"
puts

conn = MarchHare.connect

ch   = conn.create_channel
q    = ch.queue("", :exclusive => true, :arguments => {"x-expires" => 300})

sleep 0.4
begin
  # this will raise because the queue is already deleted
  q.message_count
rescue MarchHare::NotFound => nfe
  puts "Got a 404 response: the queue has already been removed"
end

sleep 0.7
puts "Closing..."
conn.close
