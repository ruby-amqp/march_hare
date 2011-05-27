$: << 'lib'

require 'hot_bunnies'


connection = HotBunnies.connect(:host => 'localhost')
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

subscription = queue.subscribe(:ack => true)
subscription.each(:blocking => true) do |headers, msg|
  puts msg
  headers.ack
  if msg == "POISON!"
    :cancel
  end
end

puts "ALL DONE!"

at_exit do
  channel.close
  connection.close
end
