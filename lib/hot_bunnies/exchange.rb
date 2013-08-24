# encoding: utf-8

module HotBunnies
  import com.rabbitmq.client.AMQP

  # Represents AMQP 0.9.1 exchanges.
  #
  # @see http://hotbunnies.info/articles/exchanges.html Exchanges and Publishing guide
  # @see http://hotbunnies.info/articles/extensions.html RabbitMQ Extensions guide
  class Exchange
    # @return [String] Exchange name
    attr_reader :name
    # @return [HotBunnies::Channel] Channel this exchange object uses
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

    def publish(body, opts = {})
      options = {:routing_key => '', :mandatory => false}.merge(opts)
      @channel.basic_publish(@name,
                             options[:routing_key],
                             options[:mandatory],
                             options.fetch(:properties, Hash.new),
                             body.to_java_bytes)
    end

    def delete(options={})
      @channel.exchange_delete(@name, options.fetch(:if_unused, false))
    end

    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.exchange_bind(@name, exchange_name, options.fetch(:routing_key, ''))
    end

    def predefined?
      @name.empty? || @name.start_with?("amq.")
    end

    #
    # Implementation
    #

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
