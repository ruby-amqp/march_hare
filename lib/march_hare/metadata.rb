module MarchHare
  class Headers
    attr_reader :channel, :consumer_tag, :envelope, :properties

    def initialize(channel, consumer_tag, envelope, properties)
      @channel      = channel
      @consumer_tag = consumer_tag
      @envelope     = envelope
      @properties   = properties
    end

    def ack(options={})
      @channel.basic_ack(delivery_tag, options.fetch(:multiple, false))
    end

    def reject(options={})
      @channel.basic_reject(delivery_tag, options.fetch(:requeue, false))
    end

    begin :envelope_delegation
      [
        :routing_key,
        :redeliver,
        :exchange
      ].each do |envelope_property|
        define_method(envelope_property) { @envelope.__send__(envelope_property) }
      end

      alias_method :redelivered?, :redeliver
    end

    def delivery_tag
      @delivery_tag ||= VersionedDeliveryTag.new(@envelope.delivery_tag, @channel.recoveries_counter.get)
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
      end # each
    end

    def persistent?
      delivery_mode == 2
    end

    def redelivered?
      redeliver
    end

    def redelivery?
      redeliver
    end
  end # Headers


  class BasicPropertiesBuilder
    def self.build_properties_from(props = {})
      builder = AMQP::BasicProperties::Builder.new

      builder.content_type(props[:content_type]).
        content_encoding(props[:content_encoding]).
        headers(props[:headers]).
        delivery_mode(props[:persistent] ? 2 : 1).
        priority(props[:priority]).
        correlation_id(props[:correlation_id]).
        reply_to(props[:reply_to]).
        expiration(if props[:expiration] then props[:expiration].to_s end).
        message_id(props[:message_id]).
        timestamp(props[:timestamp]).
        type(props[:type]).
        user_id(props[:user_id]).
        app_id(props[:app_id]).
        cluster_id(props[:cluster_id]).
        build
    end
  end
end # MarchHare
