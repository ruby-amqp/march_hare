$: << 'lib'

require 'hot_bunnies'


connection = HotBunnies.connect(:host => 'localhost')
channel = connection.create_channel
channel.prefetch = 10

exchange = channel.exchange('test', :type => :direct)

queue = channel.queue('hello.world')
queue.bind(exchange, :routing_key => 'xyz')
queue.purge

consumer = queue.subscribe(:ack => true, :blocking => false) do |headers, msg|
  puts msg
  headers.ack
end

100.times do |i|
  exchange.publish("hello world! #{i}", :routing_key => 'xyz')
end

# make sure all messages are processed before we cancel
# to avoid confusing exceptions from the [already shutdown] executor. MK.
sleep 1.0
consumer.cancel

puts "Disconnecting now..."

at_exit do
  channel.close
  connection.close
end
