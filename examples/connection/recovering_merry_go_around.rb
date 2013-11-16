#!/usr/bin/env ruby
# encoding: utf-8

require "bundler"
Bundler.setup

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'march_hare'

c1 = MarchHare.connect(:heartbeat_interval => 8)
c2 = MarchHare.connect(:heartbeat_interval => 8)

s   = 32
n   = 1000
xs  = []
chs = []
qs  = []
cs  = []

s.times do |i|
  ch = c1.create_channel
  chs << ch

  next_q = qs.last

  q  = ch.queue("", :exclusive => true)
  qs << q

  cs << q.subscribe do |_, payload|
    if next_q
      next_q.publish(payload)
    else
      puts "#{payload} has reached queue #{q.name}"
    end
  end
end

pch = c2.create_channel
x   = pch.default_exchange

loop do
  sleep 1.0
  10.times do
    x.publish("msg #{rand}", :routing_key => qs.last.name) if pch.open?
  end
end
