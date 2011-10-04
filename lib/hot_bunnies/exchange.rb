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
        else @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:internal], @options[:arguments])
        end
      end
    end


    protected

    def build_properties_from(props = {})
      builder = AMQP::BasicProperties::Builder.new

      builder.content_type(props[:content_type]).
        content_encoding(props[:content_encoding]).
        headers(props[:headers]).
        delivery_mode(props[:persistent] ? 2 : 1).
        priority(props[:priority]).
        correlation_id(props[:correlation_id]).
        reply_to(props[:reply_to]).
        expiration(props[:expiration]).
        message_id(props[:message_id]).
        timestamp(props[:timestamp]).
        type(props[:type]).
        user_id(props[:user_id]).
        app_id(props[:app_id]).
        cluster_id(props[:cluster_id]).
        build
    end # build_properties_from(props)

  end
end
