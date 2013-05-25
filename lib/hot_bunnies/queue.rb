# encoding: utf-8

require "hot_bunnies/juc"
require "hot_bunnies/metadata"
require "hot_bunnies/consumers"

module HotBunnies
  class Queue
    attr_reader :name, :channel

    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false, :passive => false, :arguments => Hash.new}.merge(options)
      declare!
    end

    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_bind(@name, exchange_name, options.fetch(:routing_key, ''), options[:arguments])
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

    def get(options = {:block => false})
      response = @channel.basic_get(@name, !options.fetch(:ack, false))

      if response
        [Headers.new(@channel, nil, response.envelope, response.props), String.from_java_bytes(response.body)]
      else
        nil
      end
    end
    alias pop get

    def subscribe(options={}, &block)
      subscription = Subscription.new(@channel, @name, options)
      subscription.each(options, &block) if block
      subscription
    end

    def status
      response = @channel.queue_declare_passive(@name)
      [response.message_count, response.consumer_count]
    end

    def message_count
      response = @channel.queue_declare_passive(@name)
      response.message_count
    end

    def consumer_count
      response = @channel.queue_declare_passive(@name)
      response.consumer_count
    end


    class Subscription
      attr_reader :channel, :queue_name, :consumer_tag

      def initialize(channel, queue_name, options = {})
        @channel    = channel
        @queue_name = queue_name
        @ack        = options.fetch(:ack, false)

        @cancelled  = JavaConcurrent::AtomicBoolean.new(false)
      end

      def each(options={}, &block)
        raise 'The subscription already has a message listener' if @consumer
        start(create_consumer(options, block))
        nil
      end
      alias_method :each_message, :each

      def start(consumer)
        @consumer = consumer
        @consumer_tag = @channel.basic_consume(@queue_name, !@ack, @consumer)
        @consumer.start
      end

      def cancel
        raise 'Can\'t cancel: the subscriber haven\'t received basic.consume-ok yet (consumer tag is not known)' if !self.active?
        response = @consumer.cancel

        # RabbitMQ Java client won't clear consumer_tag from cancelled consumers,
        # so we have to do this. Sharing consumers
        # between threads in general is a can of worms but someone somewhere
        # will almost certainly do it, so. MK.
        @cancelled.set(true)

        maybe_shutdown_executor

        response
      end

      def cancelled?
        @cancelled.get
      end

      def active?
        !@cancelled.get && !@consumer.nil? && !@consumer.consumer_tag.nil?
      end

      def shutdown!
        if @executor && @shut_down_executor
          @executor.shutdown_now
        end
      end
      alias shut_down! shutdown!

      private

      def maybe_shutdown_executor
        if @executor && @shut_down_executor
          @executor.shutdown
          unless @executor.await_termination(1, JavaConcurrent::TimeUnit::SECONDS)
            @executor.shutdown_now
          end
        end
      end

      def create_consumer(options, callback)
        block_caller = options[:block] || options[:blocking]

        if block_caller
          BlockingCallbackConsumer.new(@channel, options[:buffer_size], callback)
        else
          if options[:executor]
            @shut_down_executor = false
            @executor = options[:executor]
          else
            @shut_down_executor = true
            @executor = JavaConcurrent::Executors.new_single_thread_executor
          end
          AsyncCallbackConsumer.new(@channel, callback, @executor)
        end
      end
    end

    private

    def declare!
      response = if @options[:passive]
                 then @channel.queue_declare_passive(@name)
                 else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], @options[:arguments])
                 end
      @name = response.queue
    end
  end # Queue
end # HotBunnies
