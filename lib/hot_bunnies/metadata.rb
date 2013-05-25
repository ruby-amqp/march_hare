module HotBunnies
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
        delivery_mode == 2
      end
    end
  end # Headers
end # HotBunnies
