$: << 'lib'

require 'hot_bunnies'


begin
  conn = HotBunnies.connect(:host => 'localhost')
  ch   = conn.create_channel
  x    = ch.default_exchange

  loop do
    10.times do
      print "."
      x.publish("")
    end

    sleep 3.0
  end
rescue HotBunnies::Exception => e
  puts "RabbitMQ connection error: #{e.message}. Will reconnect in 10 seconds..."

  sleep 10
  retry
end
