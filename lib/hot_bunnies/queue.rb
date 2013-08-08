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

      @durable      = @options[:durable]
      @exclusive    = @options[:exclusive]
      @server_named = @name.empty?
      @auto_delete  = @options[:auto_delete]
      @arguments    = @options[:arguments]
    end


    # @return [Boolean] true if this queue was declared as durable (will survive broker restart).
    # @api public
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def durable?
      @durable
    end # durable?

    # @return [Boolean] true if this queue was declared as exclusive (limited to just one consumer)
    # @api public
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def exclusive?
      @exclusive
    end # exclusive?

    # @return [Boolean] true if this queue was declared as automatically deleted (deleted as soon as last consumer unbinds).
    # @api public
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def auto_delete?
      @auto_delete
    end # auto_delete?

    # @return [Boolean] true if this queue was declared as server named.
    # @api public
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    def server_named?
      @server_named
    end # server_named?

    # @return [Hash] Additional optional arguments (typically used by RabbitMQ extensions and plugins)
    # @api public
    def arguments
      @arguments
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

    # Deletes the queue
    #
    # @option [Boolean] if_unused (false) Should this queue be deleted only if it has no consumers?
    # @option [Boolean] if_empty (false) Should this queue be deleted only if it has no messages?
    #
    # @see http://hotbunnies.info/articles/queues.html Queues and Consumers guide
    # @api public
    def delete(if_unused = false, if_empty = false)
      @channel.queue_delete(@name, if_unused, if_empty)
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
        BlockingCallbackConsumer.new(@channel, self, opts[:buffer_size], opts, block)
      else
        AsyncCallbackConsumer.new(@channel, self, opts, block, opts.fetch(:executor, JavaConcurrent::Executors.new_single_thread_executor))
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
