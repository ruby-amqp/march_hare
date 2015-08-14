#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "march_hare"

connection = MarchHare.connect

ch  = connection.create_channel
# topic exchange name can be any string
x   = ch.topic("weathr", :auto_delete => true)

# Subscribers.
ch.queue("", :exclusive => true).bind(x, :routing_key => "americas.north.#").subscribe do |metadata, payload|
  puts "An update for North America: #{payload}, routing key is #{metadata.routing_key}"
end
ch.queue("americas.south").bind(x, :routing_key => "americas.south.#").subscribe do |metadata, payload|
  puts "An update for South America: #{payload}, routing key is #{metadata.routing_key}"
end
ch.queue("us.california").bind(x, :routing_key => "americas.north.us.ca.*").subscribe do |metadata, payload|
  puts "An update for US/California: #{payload}, routing key is #{metadata.routing_key}"
end
ch.queue("us.tx.austin").bind(x, :routing_key => "#.tx.austin").subscribe do |metadata, payload|
  puts "An update for Austin, TX: #{payload}, routing key is #{metadata.routing_key}"
end
ch.queue("it.rome").bind(x, :routing_key => "europe.italy.rome").subscribe do |metadata, payload|
  puts "An update for Rome, Italy: #{payload}, routing key is #{metadata.routing_key}"
end
ch.queue("asia.hk").bind(x, :routing_key => "asia.southeast.hk.#").subscribe do |metadata, payload|
  puts "An update for Hong Kong: #{payload}, routing key is #{metadata.routing_key}"
end

x.publish("San Diego update",     :routing_key => "americas.north.us.ca.sandiego")
x.publish("Berkeley update",      :routing_key => "americas.north.us.ca.berkeley")
x.publish("San Francisco update", :routing_key => "americas.north.us.ca.sanfrancisco")
x.publish("New York update",      :routing_key => "americas.north.us.ny.newyork")
x.publish("São Paolo update",     :routing_key => "americas.south.brazil.saopaolo")
x.publish("Hong Kong update",     :routing_key => "asia.southeast.hk.hongkong")
x.publish("Kyoto update",         :routing_key => "asia.southeast.japan.kyoto")
x.publish("Shanghai update",      :routing_key => "asia.southeast.prc.shanghai")
x.publish("Rome update",          :routing_key => "europe.italy.roma")
x.publish("Paris update",         :routing_key => "europe.france.paris")

sleep 1.0

connection.close
