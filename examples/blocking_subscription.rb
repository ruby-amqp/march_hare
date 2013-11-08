$: << 'lib'

require 'march_hare'


connection = MarchHare.connect(:host => 'localhost')
channel = connection.create_channel
channel.prefetch = 10

exchange = channel.exchange('test', :type => :direct)

queue = channel.queue('hello.world')
queue.bind(exchange, :routing_key => 'xyz')
queue.purge

100.times do |i|
  exchange.publish("hello world! #{i}", :routing_key => 'xyz')
end

exchange.publish("POISON!", :routing_key => 'xyz')

puts "Registering a consumer"

consumer = queue.build_consumer(:block => true) do |headers, msg|
  puts msg
  headers.ack
  consumer.cancel if msg == "POISON!"
end
queue.subscribe_with(consumer, :manual_ack => true)

puts "Disconnecting now..."

at_exit do
  channel.close
  connection.close
end
