# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'


module HotBunnies
  import com.rabbitmq.client.ConnectionFactory
  import com.rabbitmq.client.Connection
  import com.rabbitmq.client.Channel
  import com.rabbitmq.client.DefaultConsumer
  import com.rabbitmq.client.QueueingConsumer

  CONNECTION_PROPERTIES = [:host, :port, :virtual_host, :connection_timeout, :username, :password]
  
  def self.connect(options={})
    cf = ConnectionFactory.new
    CONNECTION_PROPERTIES.each do |property|
      if options[property]
        cf.send("#{property}=".to_sym, options[property]) 
      end
    end
    cf.new_connection
  end
end

require 'hot_bunnies/channel'
require 'hot_bunnies/queue'
require 'hot_bunnies/exchange'
