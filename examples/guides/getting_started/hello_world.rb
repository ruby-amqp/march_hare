#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "hot_bunnies"

conn = HotBunnies.connect

ch = conn.create_channel
q  = ch.queue("bunny.examples.hello_world", :auto_delete => true)

c  = q.subscribe do |metadata, payload|
  puts "Received #{payload}"
end

q.publish("Hello!", :routing_key => q.name)

sleep 1.0

c.cancel
conn.close
