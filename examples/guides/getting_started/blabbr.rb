#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

conn = MarchHare.connect

ch  = conn.create_channel
x   = ch.fanout("march_hare.nba.scores")

ch.queue("joe",   :auto_delete => true).bind(x).subscribe do |meta, payload|
  puts "#{payload} => joe"
end

ch.queue("aaron", :auto_delete => true).bind(x).subscribe do |meta, payload|
  puts "#{payload} => aaron"
end

ch.queue("bob",   :auto_delete => true).bind(x).subscribe do |meta, payload|
  puts "#{payload} => bob"
end

x.publish("BOS 101, NYK 89")
x.publish("ORL 85, ALT 88")
sleep 1.0

conn.close
