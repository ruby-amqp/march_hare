# encoding: utf-8

module MarchHare
  import com.rabbitmq.client.AMQP

  # Represents AMQP 0.9.1 exchanges.
  #
  # @see http://hotbunnies.info/articles/exchanges.html Exchanges and Publishing guide
  # @see http://hotbunnies.info/articles/extensions.html RabbitMQ Extensions guide
  class Exchange
    # @return [String] Exchange name
    attr_reader :name
    # @return [MarchHare::Channel] Channel this exchange object uses
    attr_reader :channel

    # Type of this exchange (one of: :direct, :fanout, :topic, :headers).
    # @return [Symbol]
    attr_reader :type

    def initialize(channel, name, options = {})
      raise ArgumentError, "exchange channel cannot be nil" if channel.nil?
      raise ArgumentError, "exchange name cannot be nil" if name.nil?
      raise ArgumentError, "exchange :type must be specified as an option" if options[:type].nil?

      @channel = channel
      @name    = name
      @type    = options[:type]
      @options = {:type => :fanout, :durable => false, :auto_delete => false, :internal => false, :passive => false}.merge(options)
    end

    # Publishes a message
    #
    # @param [String] payload Message payload. It will never be modified by MarchHare or RabbitMQ in any way.
    # @param [Hash] opts Message properties (metadata) and delivery settings
    #
    # @option opts [String] :routing_key Routing key
    # @option opts [Boolean] :persistent Should the message be persisted to disk?
    # @option opts [Boolean] :mandatory Should the message be returned if it cannot be routed to any queue?
    # @option opts [Integer] :timestamp A timestamp associated with this message
    # @option opts [Integer] :expiration Expiration time after which the message will be deleted
    # @option opts [String] :type Message type, e.g. what type of event or command this message represents. Can be any string
    # @option opts [String] :reply_to Queue name other apps should send the response to
    # @option opts [String] :content_type Message content type (e.g. application/json)
    # @option opts [String] :content_encoding Message content encoding (e.g. gzip)
    # @option opts [String] :correlation_id Message correlated to this one, e.g. what request this message is a reply for
    # @option opts [Integer] :priority Message priority, 0 to 9. Not used by RabbitMQ, only applications
    # @option opts [String] :message_id Any message identifier
    # @option opts [String] :user_id Optional user ID. Verified by RabbitMQ against the actual connection username
    # @option opts [String] :app_id Optional application ID
    #
    # @return [MarchHare::Exchange] Self
    # @see http://hotbunnies.info/articles/exchanges.html Exchanges and Publishing guide
    # @api public
    def publish(body, opts = {})
      options = {:routing_key => '', :mandatory => false}.merge(opts)
      @channel.basic_publish(@name,
                             options[:routing_key],
                             options[:mandatory],
                             options.fetch(:properties, Hash.new),
                             body.to_java_bytes)
    end

    # Deletes the exchange unless it is predefined
    #
    # @param [Hash] options Options
    #
    # @option opts [Boolean] if_unused (false) Should this exchange be deleted only if it is no longer used
    #
    # @see http://hotbunnies.info/articles/exchanges.html Exchanges and Publishing guide
    # @api public
    def delete(options={})
      @channel.deregister_exchange(self)
      @channel.exchange_delete(@name, options.fetch(:if_unused, false)) unless predefined?
    end

    # Binds an exchange to another (source) exchange using exchange.bind AMQP 0.9.1 extension
    # that RabbitMQ provides.
    #
    # @param [String] exchange Source exchange name
    # @param [Hash] options Options
    #
    # @option opts [String] routing_key (nil) Routing key used for binding
    # @option opts [Hash] arguments ({}) Optional arguments
    #
    # @return [MarchHare::Exchange] Self
    # @see http://hotbunnies.info/articles/exchanges.html Exchanges and Publishing guide
    # @see http://hotbunnies.info/articles/bindings.html Bindings guide
    # @see http://hotbunnies.info/articles/extensions.html RabbitMQ Extensions guide
    # @api public
    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.exchange_bind(@name, exchange_name, options.fetch(:routing_key, ''))
    end

    # Unbinds an exchange from another (source) exchange using exchange.unbind AMQP 0.9.1 extension
    # that RabbitMQ provides.
    #
    # @param [String] source Source exchange name
    # @param [Hash] opts Options
    #
    # @option opts [String] routing_key (nil) Routing key used for binding
    # @option opts [Hash] arguments ({}) Optional arguments
    #
    # @return [Bunny::Exchange] Self
    # @see http://rubybunny.info/articles/exchanges.html Exchanges and Publishing guide
    # @see http://rubybunny.info/articles/bindings.html Bindings guide
    # @see http://rubybunny.info/articles/extensions.html RabbitMQ Extensions guide
    # @api public
    def unbind(exchange, opts = {})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.exchange_unbind(@name, exchange_name, opts.fetch(:routing_key, ''), opts[:arguments])
    end

    # @return [Boolean] true if this exchange is a pre-defined one (amq.direct, amq.fanout, amq.match and so on)
    def predefined?
      @name.empty? || @name.start_with?("amq.")
    end

    # Waits until all outstanding publisher confirms on the channel
    # arrive.
    #
    # This is a convenience method that delegates to {Channel#wait_for_confirms}
    #
    # @api public
    def wait_for_confirms
      @channel.wait_for_confirms
    end


    #
    # Implementation
    #

    # @private
    def declare!
      unless predefined?
        if @options[:passive]
        then @channel.exchange_declare_passive(@name)
        else @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:arguments])
        end
      end
    end

    # @private
    def recover_from_network_failure
      # puts "Recovering exchange #{@name} from network failure"
      declare! unless predefined?
    end
  end
end
