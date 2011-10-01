# encoding: utf-8

module HotBunnies
  class Exchange
    attr_reader :name, :channel

    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:type => :fanout, :durable => false, :auto_delete => false, :internal => false, :passive => false}.merge(options)
    end

    def publish(body, options={})
      options = {:routing_key => '', :mandatory => false, :immediate => false}.merge(options)
      @channel.basic_publish(@name, options[:routing_key], options[:mandatory], options[:immediate], build_properties_from(options.fetch(:properties, Hash.new)), body.to_java_bytes)
    end

    def delete(options={})
      @channel.exchange_delete(@name, options.fetch(:if_unused, false))
    end

    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.exchange_bind(@name, exchange_name, options.fetch(:routing_key, ''))
    end

    def declare!
      unless @name == ''
        if @options[:passive]
        then @channel.exchange_declare_passive(@name)
        else @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:internal], nil)
        end
      end
    end


    protected

    def build_properties_from(props = {})
      builder = AMQP::BasicProperties.new(props[:content_type],
                                          props[:content_encoding],
                                          props[:headers],
                                          props[:persistent] ? 2 : 1,
                                          props[:priority],
                                          props[:correlation_id],
                                          props[:reply_to],
                                          props[:expiration],
                                          props[:message_id],
                                          props[:timestamp],
                                          props[:type],
                                          props[:user_id],
                                          props[:app_id],
                                          props[:cluster_id])
    end # build_properties_from(props)

  end
end

