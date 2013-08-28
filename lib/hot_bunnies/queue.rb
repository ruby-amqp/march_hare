# encoding: utf-8

require "hot_bunnies/juc"
require "hot_bunnies/metadata"
require "hot_bunnies/consumers"
require "set"

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
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false, :passive => false, :arguments => Hash.new}.merge(options)

      @durable      = @options[:durable]
      @exclusive    = @options[:exclusive]
      @server_named = @name.empty?
      @auto_delete  = @options[:auto_delete]
      @arguments    = @options[:arguments]

      @bindings     = Set.new
    end


    # @return [Boolean] true if this queue was declared as durable (will survive broker restart).
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def durable?
      @durable
    end # durable?

    # @return [Boolean] true if this queue was declared as exclusive (limited to just one consumer)
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def exclusive?
      @exclusive
    end # exclusive?

    # @return [Boolean] true if this queue was declared as automatically deleted (deleted as soon as last consumer unbinds).
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def auto_delete?
      @auto_delete
    end # auto_delete?

    # @return [Boolean] true if this queue was declared as server named.
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def server_named?
      @server_named
    end # server_named?

    # @return [Hash] Additional optional arguments (typically used by RabbitMQ extensions and plugins)
    def arguments
      @arguments
    end



    # Binds queue to an exchange
    #
    # @param [HotBunnies::Exchange,String] exchange Exchange to bind to
    # @param [Hash] options Binding properties
    #
    # @option options [String] :routing_key  Routing key
    # @option options [Hash] :arguments ({}) Additional optional binding arguments
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @see http://hotbunnies.info/articles/bindings.html Bindings guide
    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then
                        exchange.name
                      else
                        exchange.to_s
                      end
      @channel.queue_bind(@name, exchange_name, (options[:routing_key] || options[:key] || ""), options[:arguments])

      # store bindings for automatic recovery. We need to be very careful to
      # not cause an infinite rebinding loop here when we recover. MK.
      binding = { :exchange => exchange_name, :routing_key => (options[:routing_key] || options[:key]), :arguments => options[:arguments] }
      @bindings << binding unless @bindings.include?(binding)

      self
    end

    # Unbinds queue from an exchange
    #
    # @param [HotBunnies::Exchange,String] exchange Exchange to unbind from
    # @param [Hash] options                       Binding properties
    #
    # @option options [String] :routing_key  Routing key
    # @option options [Hash] :arguments ({}) Additional optional binding arguments
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @see http://hotbunnies.info/articles/bindings.html Bindings guide
    def unbind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then
                        exchange.name
                      else
                        exchange.to_s
                      end
      @channel.queue_unbind(@name, exchange_name, options.fetch(:routing_key, ''))

      binding = { :exchange => exchange_name, :routing_key => (options[:routing_key] || options[:key] || ""), :arguments => options[:arguments] }
      @bindings.delete(binding) unless @bindings.include?(binding)

      self
    end

    # Deletes the queue
    #
    # @option [Boolean] if_unused (false) Should this queue be deleted only if it has no consumers?
    # @option [Boolean] if_empty (false) Should this queue be deleted only if it has no messages?
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def delete(if_unused = false, if_empty = false)
      @channel.queue_delete(@name, if_unused, if_empty)
    end

    # Purges a queue (removes all messages from it)
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @api public
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

    def build_consumer(opts = {}, &block)
      if opts[:block] || opts[:blocking]
        BlockingCallbackConsumer.new(@channel, self, opts[:buffer_size], opts, block)
      else
        CallbackConsumer.new(@channel, self, opts, block)
      end
    end

    # Adds a consumer to the queue (subscribes for message deliveries).
    #
    # @param [Hash] opts Options
    #
    # @option opts [Boolean] :manual_ack (false) Will this consumer use manual acknowledgements?
    # @option opts [Boolean] :exclusive (false) Should this consumer be exclusive for this queue?
    # @option opts [Boolean] :block (false) Should the call block calling thread?
    # @option opts [#call] :on_cancellation Block to execute when this consumer is cancelled remotely (e.g. via the RabbitMQ Management plugin)
    # @option opts [String] :consumer_tag Unique consumer identifier. It is usually recommended to let HotBunnies generate it for you.
    # @option opts [Hash] :arguments ({}) Additional (optional) arguments, typically used by RabbitMQ extensions
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @api public
    def subscribe(opts = {}, &block)
      subscribe_with(build_consumer(opts, &block), opts)
    end

    def subscribe_with(consumer, opts = {})
      @consumer_tag     = @channel.basic_consume(@name, !(opts[:ack] || opts[:manual_ack]), consumer)
      consumer.consumer_tag = @consumer_tag

      @default_consumer = consumer
      @channel.register_consumer(@consumer_tag, consumer)

      consumer.start
      consumer
    end

    # @return [Array<Integer>] A pair with information about the number of queue messages and consumers
    # @see #message_count
    # @see #consumer_count
    def status
      response = @channel.queue_declare_passive(@name)
      [response.message_count, response.consumer_count]
    end

    # @return [Integer] How many messages the queue has ready (e.g. not delivered but not unacknowledged)
    def message_count
      response = @channel.queue_declare_passive(@name)
      response.message_count
    end

    # @return [Integer] How many active consumers the queue has
    def consumer_count
      response = @channel.queue_declare_passive(@name)
      response.consumer_count
    end

    # Publishes a message to the queue via default exchange. Takes the same arguments
    # as {HotBunnies::Exchange#publish}
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

    # @private
    def declare!
      response = if @options[:passive]
                 then @channel.queue_declare_passive(@name)
                 else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], @options[:arguments])
                 end
      @name = response.queue
    end

    # @private
    def recover_from_network_failure
      if self.server_named?
        old_name = @name.dup
        @name    = ""

        @channel.deregister_queue_named(old_name)
      end

      # puts "Recovering queue #{@name}"
      begin
        declare!

        @channel.register_queue(self)
      rescue Exception => e
        # TODO: use a logger
        puts "Caught #{e.inspect} while redeclaring and registering #{@name}!"
      end
      recover_bindings
    end

    # @private
    def recover_bindings
      @bindings.each do |b|
        # TODO: use a logger
        # puts "Recovering binding #{b.inspect}"
        self.bind(b[:exchange], b)
      end
    end
  end # Queue
end # HotBunnies
