#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

puts "=> Demonstrating basic.nack"
puts

conn = MarchHare.connect

ch   = conn.create_channel
q    = ch.queue("", :exclusive => true)

20.times do
  q.publish("")
end

20.times do
  metadata, _ = q.pop(:ack => true)

  if metadata.delivery_tag == 20
    # requeue them all at once with basic.nack
    ch.nack(metadata.delivery_tag, true, true)
  end
end

puts "Queue #{q.name} still has #{q.message_count} messages in it"

sleep 0.7
puts "Disconnecting..."
conn.close
