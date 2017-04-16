$: << 'lib'

require 'march_hare'

connection = MarchHare.connect(:host => 'localhost')
channel = connection.create_channel
channel.prefetch = 10

exchange = channel.exchange('test', :type => :direct)

queue = channel.queue('hello.world')
queue.bind(exchange, :routing_key => 'xyz')
queue.purge

# See how all three pools affect the output:
pool = ::MarchHare::ThreadPools.dynamically_growing
#pool = ::MarchHare::ThreadPools.fixed_of_size 6
#pool = ::MarchHare::ThreadPools.single_threaded

consumer = queue.subscribe(:ack => true, :blocking => false, :executor => pool) do |headers, msg|
  pool.submit do
    puts msg
    headers.ack
  end
end

100.times do |i|
  exchange.publish("hello world! #{i}", :routing_key => 'xyz')
end

# make sure all messages are processed before we cancel
# to avoid confusing exceptions from the [already shutdown] executor. MK.
sleep 2.0
consumer.cancel

puts "Disconnecting now..."

at_exit do
  channel.close
  connection.close
  pool.shutdown
end
