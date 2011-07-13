# encoding: utf-8

module HotBunnies
  class Queue
    attr_reader :name, :channel
    
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false, :passive => false}.merge(options)
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
      if response
      then [Headers.new(@channel, nil, response.envelope, response.props), String.from_java_bytes(response.body)]
      else nil
      end
    end
    
    def subscribe(options={}, &block)
      subscription = Subscription.new(@channel, @name, options)
      subscription.each(options, &block) if block
      subscription
    end
    
    def status
      response = @channel.queue_declare_passive(@name)
      [response.message_count, response.consumer_count]
    end

  private
  
    def declare!
      response = if @options[:passive]
      then @channel.queue_declare_passive(@name)
      else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], nil)
      end
      @name = response.queue
    end
    
    class Subscription
      def initialize(channel, queue_name, options={})
        @channel = channel
        @queue_name = queue_name
        @ack = options.fetch(:ack, false)
      end
      
      def each(options={}, &block)
        raise 'The subscription already has a message listener' if @subscriber
        if options.fetch(:blocking, true)
          run(&block)
        else
          if options[:executor]
            @shut_down_executor = false
            @executor = options[:executor]
          else
            @shut_down_executor = true
            @executor = java.util.concurrent.Executors.new_single_thread_executor
          end
          @executor.submit { run(&block) }
        end
      end

      def cancel
        raise 'Can\'t cancel: the subscriber haven\'t received an OK yet' if !@subscriber || !@subscriber.consumer_tag
        @channel.basic_cancel(@subscriber.consumer_tag)
        @executor.shutdown_now if @executor && @shut_down_executor
      end
      
    private
    
      def run(&block)
        @subscriber = BlockingSubscriber.new(@channel, self)
        @channel.basic_consume(@queue_name, !@ack, @subscriber.consumer)
        @subscriber.on_message(&block)
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
        @channel.basic_ack(delivery_tag, options.fetch(:multiple, false))
      end
      
      def reject(options={})
        @channel.basic_ack(delivery_tag, options.fetch(:requeue, false))
      end
      
      def delivery_tag
        @envelope.delivery_tag
      end
    end
  
    module Subscriber
      def start
        # to be implemented by the host class
      end
      
      def on_message(&block)
        raise ArgumentError, 'Message listener already registered for this subscriber' if @subscriber
        @subscriber = block
        start
      end
      
      def handle_message(consumer_tag, envelope, properties, body_bytes)
        body = String.from_java_bytes(body_bytes)
        case @subscriber.arity
        when 2 then @subscriber.call(Headers.new(@channel, consumer_tag, envelope, properties), body)
        when 1 then @subscriber.call(body)
        else raise ArgumentError, 'Consumer callback wants no arguments'
        end
      end
    end
  
    class BlockingSubscriber
      include Subscriber
      
      attr_reader :consumer
      
      def initialize(channel, subscription)
        @channel = channel
        @subscription = subscription
        @consumer = QueueingConsumer.new(@channel)
      end
      
      def consumer_tag
        @consumer.consumer_tag
      end
      
      def start
        super
        while delivery = @consumer.next_delivery
          result = handle_message(@consumer.consumer_tag, delivery.envelope, delivery.properties, delivery.body)
          if result == :cancel
            @subscription.cancel
            while delivery = @consumer.next_delivery(0)
              handle_message(@consumer.consumer_tag, delivery.envelope, delivery.properties, delivery.body)
            end
            break
          end
        end
      end
    end
  end
end
