# encoding: utf-8

module JavaConcurrent
  java_import 'java.lang.Thread'
  java_import 'java.lang.InterruptedException'
  java_import 'java.util.concurrent.Executors'
  java_import 'java.util.concurrent.LinkedBlockingQueue'
  java_import 'java.util.concurrent.ArrayBlockingQueue'
  java_import 'java.util.concurrent.TimeUnit'
  java_import 'java.util.concurrent.atomic.AtomicBoolean'
end

module HotBunnies
  import com.rabbitmq.client.DefaultConsumer

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

    def get(options={})
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

    private

    def declare!
      response = if @options[:passive]
                 then @channel.queue_declare_passive(@name)
                 else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], @options[:arguments])
                 end
      @name = response.queue
    end

    class Subscription
      include JavaConcurrent

      attr_reader :channel, :queue_name, :consumer_tag

      def initialize(channel, queue_name, options={})
        @channel    = channel
        @queue_name = queue_name
        @ack        = options.fetch(:ack, false)

        @cancelled  = AtomicBoolean.new(false)
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
        raise 'Can\'t cancel: the subscriber haven\'t received an OK yet' if !self.active?
        @consumer.cancel

        # RabbitMQ Java client won't clear consumer_tag from cancelled consumers,
        # so we have to do this. Sharing consumers
        # between threads in general is a can of worms but someone somewhere
        # will almost certainly do it, so. MK.
        @cancelled.set(true)

        maybe_shutdown_executor
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
          unless @executor.await_termination(1, TimeUnit::SECONDS)
            @executor.shutdown_now
          end
        end
      end

      def create_consumer(options, callback)
        if options.fetch(:blocking, true)
          BlockingCallbackConsumer.new(@channel, options[:buffer_size], callback)
        else
          if options[:executor]
            @shut_down_executor = false
            @executor = options[:executor]
          else
            @shut_down_executor = true
            @executor = Executors.new_single_thread_executor
          end
          AsyncCallbackConsumer.new(@channel, callback, @executor)
        end
      end
    end

    public

    class BaseConsumer < DefaultConsumer
      def handleDelivery(consumer_tag, envelope, properties, body)
        body = String.from_java_bytes(body)
        headers = Headers.new(channel, consumer_tag, envelope, properties)
        deliver(headers, body)
      end

      def handleCancel(consumer_tag)
        @cancelled = true
      end

      def handleCancelOk(consumer_tag)
        @cancelled = true
      end

      def start
      end

      def deliver(headers, message)
        raise NotImplementedError, 'To be implemented by a subclass'
      end

      def cancel
        channel.basic_cancel(consumer_tag)
        @cancelling = true
      end
    end

    private

    class CallbackConsumer < BaseConsumer
      def initialize(channel, callback)
        super(channel)
        @callback = callback
        @callback_arity = @callback.arity
        @cancelled = false
        @cancelling = false
      end

      def callback(headers, message)
        if @callback_arity == 2
          @callback.call(headers, message)
        else
          @callback.call(message)
        end
      end
    end

    class AsyncCallbackConsumer < CallbackConsumer
      def initialize(channel, callback, executor)
        super(channel, callback)
        @executor = executor
        @tasks = []
      end

      def deliver(headers, message)
        unless @executor.shutdown?
          @executor.submit do
            callback(headers, message)
          end
        end
      end
    end

    class BlockingCallbackConsumer < CallbackConsumer
      include JavaConcurrent

      def initialize(channel, buffer_size, callback)
        super(channel, callback)
        if buffer_size
          @internal_queue = ArrayBlockingQueue.new(buffer_size)
        else
          @internal_queue = LinkedBlockingQueue.new
        end
      end

      def start
        interrupted = false
        until @cancelled || JavaConcurrent::Thread.current_thread.interrupted?
          begin
            pair = @internal_queue.take
            callback(*pair) if pair
          rescue InterruptedException => e
            interrupted = true
          end
        end
        while (pair = @internal_queue.poll)
          callback(*pair)
        end
        if interrupted
          JavaConcurrent::Thread.current_thread.interrupt
        end
      end

      def deliver(*pair)
        if @cancelling || @cancelled || JavaConcurrent::Thread.current_thread.interrupted?
          @internal_queue.offer(pair)
        else
          begin
            @internal_queue.put(pair)
          rescue InterruptedException => e
            JavaConcurrent::Thread.current_thread.interrupt
          end
        end
      end
    end

    class Headers
      attr_reader :channel, :consumer_tag, :envelope, :properties

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
        @channel.basic_reject(delivery_tag, options.fetch(:requeue, false))
      end

      begin :envelope_delegation
        [
          :delivery_tag,
          :routing_key,
          :redeliver,
          :exchange
        ].each do |envelope_property|
          define_method(envelope_property) { @envelope.__send__(envelope_property) }
        end

        alias_method :redelivered?, :redeliver
      end

      begin :message_properties_delegation
        [
          :content_encoding,
          :content_type,
          :content_encoding,
          :headers,
          :delivery_mode,
          :priority,
          :correlation_id,
          :reply_to,
          :expiration,
          :message_id,
          :timestamp,
          :type,
          :user_id,
          :app_id,
          :cluster_id
        ].each do |properties_property|
          define_method(properties_property) { @properties.__send__(properties_property) }
        end

        def persistent?
          persistent == 2
        end
      end
    end
  end
end
