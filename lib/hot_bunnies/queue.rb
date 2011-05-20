# encoding: utf-8

module HotBunnies
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
    
    def get(options={})
      response = @channel.basic_get(@name, !options.fetch(:ack, false))
      [Headers.new(@channel, nil, response.envelope, response.props), Queue.bytes_to_string(response.body)]
    end
    
    def subscribe(options={}, &subscriber)
      subscriber = Subscriber.new(@channel, &subscriber)
      @channel.basic_consume(@name, !options.fetch(:ack, false), subscriber)
      Subscription.new(@channel, subscriber)
    end
    
    def status
      response = @channel.queue_declare_passive(@name)
      [response.message_count, response.consumer_count]
    end

  private
  
    def self.bytes_to_string(bytes)
      java.lang.String.new(bytes).to_s
    end
    
    class Subscription
      def initialize(channel, subscriber)
        @channel = channel
        @subscriber = subscriber
      end
      
      def cancel
        raise "Can't cancel: the subscriber haven't received an OK yet" unless @subscriber.consumer_tag
        @channel.basic_cancel(@subscriber.consumer_tag)
      end
    end
  
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
  
    class Subscriber < DefaultConsumer
      attr_reader :consumer_tag
      
      def initialize(channel, &subscriber)
        super(channel)
        @channel = channel
        @subscriber = subscriber
      end
      
      def handleConsumeOk(consumer_tag)
        @consumer_tag = consumer_tag
      end
      
      def handleDelivery(consumer_tag, envelope, properties, body_bytes)
        case @subscriber.arity
        when 2 then @subscriber.call(Headers.new(@channel, consumer_tag, envelope, properties), Queue.bytes_to_string(body_bytes))
        when 1 then @subscriber.call(body)
        else raise ArgumentError, 'Consumer callback wants no arguments'
        end
      end
    end
    
    def declare!
      @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], nil)
    end
  end
end
