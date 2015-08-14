#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

puts "=> Demonstrating consumer cancellation notification"
puts

conn = MarchHare.connect

ch   = conn.create_channel
q    = ch.queue("", :exclusive => true)
c    = q.subscribe(:on_cancellation => Proc.new { |ch, consumer, consumer_tag| puts "Consumer w/ tag #{consumer_tag} was cancelled remotely" }) do |metadata, payload|
  # no-op
end

sleep 0.1
puts "Consumer #{c.consumer_tag} is not yet cancelled" unless c.cancelled?
q.delete

sleep 0.1

puts "Consumer #{c.consumer_tag} is now cancelled" if c.cancelled?

puts "Disconnecting..."
conn.close
