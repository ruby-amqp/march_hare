# encoding: utf-8

require "hot_bunnies/juc"
require "hot_bunnies/metadata"
require "hot_bunnies/consumers"

module HotBunnies
  # Represents AMQP 0.9.1 queue.
  #
  # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
  # @see http://hotbunnies.info/articles/extensions.html RabbitMQ Extensions guide
  class Queue
    # @return [HotBunnies::Channel] Channel this queue uses
    attr_reader :channel
    # @return [String] Queue name
    attr_reader :name

    # @param [HotBunnies::Channel] channel_or_connection Channel this queue will use.
    # @param [String] name                          Queue name. Pass an empty string to make RabbitMQ generate a unique one.
    # @param [Hash] opts                            Queue properties
    #
    # @option opts [Boolean] :durable (false)      Should this queue be durable?
    # @option opts [Boolean] :auto_delete (false)  Should this queue be automatically deleted when the last consumer disconnects?
    # @option opts [Boolean] :exclusive (false)    Should this queue be exclusive (only can be used by this connection, removed when the connection is closed)?
    # @option opts [Boolean] :arguments ({})       Additional optional arguments (typically used by RabbitMQ extensions and plugins)
    #
    # @see HotBunnies::Channel#queue
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @see http://hotbunnies.info/articles/extensions.html RabbitMQ Extensions guide
    # @api public
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false, :passive => false, :arguments => Hash.new}.merge(options)
    end

    # Binds queue to an exchange
    #
    # @param [HotBunnies::Exchange,String] exchange Exchange to bind to
    # @param [Hash] opts Binding properties
    #
    # @option opts [String] :routing_key  Routing key
    # @option opts [Hash] :arguments ({}) Additional optional binding arguments
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @see http://hotbunnies.info/articles/bindings.html Bindings guide
    # @api public
    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_bind(@name, exchange_name, options.fetch(:routing_key, ''), options[:arguments])

      self
    end

    # Unbinds queue from an exchange
    #
    # @param [HotBunnies::Exchange,String] exchange Exchange to unbind from
    # @param [Hash] opts                       Binding properties
    #
    # @option opts [String] :routing_key  Routing key
    # @option opts [Hash] :arguments ({}) Additional optional binding arguments
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @see http://hotbunnies.info/articles/bindings.html Bindings guide
    # @api public
    def unbind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_unbind(@name, exchange_name, options.fetch(:routing_key, ''))

      self
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

    def build_consumer(opts, &block)
      if opts[:block] || opts[:blocking]
        BlockingCallbackConsumer.new(@channel, opts[:buffer_size], opts, block)
      else
        AsyncCallbackConsumer.new(@channel, opts, block, opts.fetch(:executor, JavaConcurrent::Executors.new_single_thread_executor))
      end
    end

    def subscribe(opts = {}, &block)
      consumer = build_consumer(opts, &block)

      @consumer_tag     = @channel.basic_consume(@name, !(opts[:ack] || opts[:manual_ack]), consumer)
      consumer.consumer_tag = @consumer_tag

      @default_consumer = consumer
      @channel.register_consumer(@consumer_tag, consumer)
      consumer.start

      consumer
    end

    def subscribe_with(consumer, opts = {})
      @consumer_tag     = @channel.basic_consume(@name, !(opts[:ack] || opts[:manual_ack]), consumer)
      consumer.consumer_tag = @consumer_tag

      @default_consumer = consumer
      @channel.register_consumer(@consumer_tag, consumer)
      consumer.start

      consumer
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

    # Publishes a message to the queue via default exchange. Takes the same arguments
    # as {Bunny::Exchange#publish}
    #
    # @see HotBunnies::Exchange#publish
    # @see HotBunnies::Channel#default_exchange
    def publish(payload, opts = {})
      @channel.default_exchange.publish(payload, opts.merge(:routing_key => @name))

      self
    end


    #
    # Implementation
    #

    def declare!
      response = if @options[:passive]
                 then @channel.queue_declare_passive(@name)
                 else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], @options[:arguments])
                 end
      @name = response.queue
    end
  end # Queue
end # HotBunnies
