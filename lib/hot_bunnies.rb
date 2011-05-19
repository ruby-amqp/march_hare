# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'


module HotBunnies
  VERSION = '1.0.0'
  
  import com.rabbitmq.client.ConnectionFactory
  import com.rabbitmq.client.Connection
  import com.rabbitmq.client.Channel
  import com.rabbitmq.client.DefaultConsumer
  
  def self.connect(options={})
    cf = ConnectionFactory.new
    cf.host = options[:host] if options[:host]
    cf.new_connection
  end
  
  module Channel
    def queue(name, options={})
      Queue.new(self, name, options)
    end
    
    def exchange(name, options={})
      Exchange.new(self, name, options)
    end
    
    def qos(options={})
      options = {:prefetch_size => 0, :prefetch_count => 0, :global => true}.merge(options)
    end
  end
  
  class Queue
    attr_reader :name
    
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false}.merge(options)
      declare!
    end
    
    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_bind(@name, exchange_name, options.fetch(:routing_key, ''))
    end
    
    def unbind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_unbind(@name, exchange_name, options.fetch(:routing_key, ''))
    end
    
    def delete
      @channel.queue_delete(@name)
    end
    
    def purge
      @channel.queue_purge(@name)
    end
    
    def subscribe(options={}, &subscriber)
      @channel.basic_consume(@name, !options.fetch(:ack, false), ConsumerWrapper.new(@channel, &subscriber))
    end

  private
  
    class Headers
      def initialize(channel, consumer_tag, envelope, properties)
        @channel = channel
        @consumer_tag = consumer_tag
        @envelope = envelope
        @properties = properties
      end
      
      def ack(options={})
        @channel.basic_ack(@envelope.delivery_tag, options.fetch(:multiple, false))
      end
      
      def reject(options={})
        @channel.basic_ack(@envelope.delivery_tag, options.fetch(:requeue, false))
      end
    end
  
    class ConsumerWrapper < DefaultConsumer
      def initialize(channel, &subscriber)
        super(channel)
        @channel = channel
        @subscriber = subscriber
      end
      
      def handleDelivery(consumer_tag, envelope, properties, body_bytes)
        body = java.lang.String.new(body_bytes).to_s
        case @subscriber.arity
        when 2 then @subscriber.call(Headers.new(@channel, consumer_tag, envelope, properties), body)
        when 1 then @subscriber.call(body)
        else raise ArgumentError, 'Consumer callback wants no arguments'
        end
      end
    end
    
    def declare!
      @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], nil)
    end
  end
  
  class Exchange
    attr_reader :name
    
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:type => :fanout, :durable => false, :auto_delete => false, :internal => false}.merge(options)
      declare!
    end
    
    def publish(body, options={})
      options = {:routing_key => '', :mandatory => false, :immediate => false}.merge(options)
      @channel.basic_publish(@name, options[:routing_key], options[:mandatory], options[:immediate], nil, body.to_java.bytes)
    end
    
    def delete(options={})
      @channel.exchange_delete(@name, options.fetch(:if_unused, false))
    end
    
  private
  
    def declare!
      unless @name == ''
        @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:internal], nil)
      end
    end
  end
end
