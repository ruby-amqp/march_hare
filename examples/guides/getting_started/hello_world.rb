#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

conn = MarchHare.connect

ch = conn.create_channel
q  = ch.queue("march_hare.examples.hello_world", :auto_delete => true)

c  = q.subscribe do |metadata, payload|
  puts "Received #{payload}"
end

q.publish("Hello!", :routing_key => q.name)

sleep 1.0

c.cancel
conn.close
