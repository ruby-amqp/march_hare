$: << 'lib'

require 'hot_bunnies'


connection = HotBunnies.connect(:host => 'localhost')
channel = connection.create_channel
channel.prefetch = 10

exchange = channel.exchange('test', :type => :direct)

queue = channel.queue('hello.world')
queue.bind(exchange, :routing_key => 'xyz')
queue.purge

subscription = queue.subscribe(:ack => true, :blocking => false) do |headers, msg|
  puts msg
  headers.ack
end

100.times do |i|
  exchange.publish("hello world! #{i}", :routing_key => 'xyz')
end

subscription.cancel

puts "ALMOST ALL DONE!"

at_exit do
  channel.close
  connection.close
end
