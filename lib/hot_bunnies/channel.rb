# encoding: utf-8

module HotBunnies
  class Channel
    attr_reader :session

    def initialize(session, delegate)
      @connection = session
      @delegate   = delegate

      # we keep track of consumers to gracefully shut down their
      # executors when the channel is closed. This frees library users
      # from having to worry about this. MK.
      @consumers  = ConcurrentHashMap.new
    end

    def client
      @connection
    end

    def id
      @delegate.channel_number
    end

    def number
      @delegate.channel_number
    end

    def channel_number
      @delegate.channel_number
    end

    def close(code = 200, reason = "Goodbye")
      v = @delegate.close(code, reason)

      @consumers.each do |tag, consumer|
        consumer.gracefully_shut_down
      end

      @connection.unregister_channel(self)

      v
    end


    # @group Exchanges

    def exchange(name, options={})
      Exchange.new(self, name, options).tap do |x|
        x.declare!
      end
    end

    def fanout(name, opts = {})
      Exchange.new(self, name, opts.merge(:type => "fanout")).tap do |x|
        x.declare!
      end
    end

    def direct(name, opts = {})
      Exchange.new(self, name, opts.merge(:type => "direct")).tap do |x|
        x.declare!
      end
    end

    def topic(name, opts = {})
      Exchange.new(self, name, opts.merge(:type => "topic")).tap do |x|
        x.declare!
      end
    end

    def headers(name, opts = {})
      Exchange.new(self, name, opts.merge(:type => "headers")).tap do |x|
        x.declare!
      end
    end

    def default_exchange
      @default_exchange ||= self.exchange("", :durable => true, :auto_delete => false, :type => "direct")
    end

    def exchange_declare(name, type, durable = false, auto_delete = false, arguments = nil)
      @delegate.exchange_declare(name, type, durable, auto_delete, arguments)
    end

    # @endgroup


    # @group Queues

    def queue(name, options={})
      Queue.new(self, name, options).tap do |q|
        q.declare!
      end
    end

    def queue_declare(name, durable, exclusive, auto_delete, arguments = {})
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_declare(name, durable, exclusive, auto_delete, arguments)
      end
    end

    def queue_declare_passive(name)
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_declare_passive(name)
      end
    end

    def queue_delete(name, if_empty = false, if_unused = false)
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_delete(name, if_empty, if_unused)
      end
    end

    def queue_bind(queue, exchange, routing_key, arguments = nil)
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_bind(queue, exchange, routing_key, arguments)
      end
    end

    def queue_unbind(queue, exchange, routing_key, arguments = nil)
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_unbind(queue, exchange, routing_key, arguments)
      end
    end

    def queue_purge(name)
      converting_rjc_exceptions_to_ruby do
        @delegate.queue_purge(name)
      end
    end

    # @endgroup


    # @group basic.*

    def basic_publish(exchange, routing_key, mandatory, properties, body)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_publish(exchange, routing_key, mandatory, false, BasicPropertiesBuilder.build_properties_from(properties || Hash.new), body)
      end
    end

    def basic_get(queue, auto_ack)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_get(queue, auto_ack)
      end
    end

    def basic_consume(queue, auto_ack, consumer)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_consume(queue, auto_ack, consumer)
      end
    end

    def basic_qos(prefetch_count)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_qos(prefetch_count)
      end
    end

    def qos(options={})
      if options.size == 1 && options[:prefetch_count]
      then basic_qos(options[:prefetch_count])
      else basic_qos(options.fetch(:prefetch_size, 0), options.fetch(:prefetch_count, 0), options.fetch(:global, false))
      end
    end

    def prefetch=(n)
      basic_qos(n)
    end

    def ack(delivery_tag, multiple = false)
      converting_rjc_exceptions_to_ruby do
        basic_ack(delivery_tag, multiple)
      end
    end
    alias acknowledge ack

    def reject(delivery_tag, requeue = false)
      converting_rjc_exceptions_to_ruby do
        basic_reject(delivery_tag, requeue)
      end
    end

    def nack(delivery_tag, multiple = false, requeue = false)
      converting_rjc_exceptions_to_ruby do
        basic_nack(delivery_tag, multiple, requeue)
      end
    end

    def basic_recover(requeue = true)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_recover(requeue)
      end
    end

    def basic_recover_async(requeue = true)
      converting_rjc_exceptions_to_ruby do
        @delegate.basic_recover_async(requeue)
      end
    end

    # @endgroup


    def confirm_select
      converting_rjc_exceptions_to_ruby do
        @delegate.confirm_select
      end
    end

    # Waits until all outstanding publisher confirms arrive.
    #
    # Takes an optional timeout in milliseconds. Will raise
    # an exception in timeout has occured.
    #
    # @param [Integer] timeout Timeout in milliseconds
    # @return [Boolean] true if all confirms were positive,
    #                        false if some were negative
    def wait_for_confirms(timeout = nil)
      if timeout
        converting_rjc_exceptions_to_ruby do
          @delegate.wait_for_confirms(timeout)
        end
      else
        @delegate.wait_for_confirms
      end
    end

    def next_publisher_seq_no
      @delegate.next_publisher_seq_no
    end

    def tx_select
      converting_rjc_exceptions_to_ruby do
        @delegate.tx_select
      end
    end

    def tx_commit
      converting_rjc_exceptions_to_ruby do
        @delegate.tx_commit
      end
    end

    def tx_rollback
      converting_rjc_exceptions_to_ruby do
        @delegate.tx_rollback
      end
    end

    def channel_flow(active)
      converting_rjc_exceptions_to_ruby do
        @delegate.channel_flow(active)
      end
    end


    def on_return(&block)
      self.add_return_listener(BlockReturnListener.from(block))
    end

    def method_missing(selector, *args)
      @delegate.__send__(selector, *args)
    end


    #
    # Implementation
    #

    class BlockReturnListener
      include com.rabbitmq.client.ReturnListener

      def self.from(block)
        new(block)
      end

      def initialize(block)
        @block = block
      end

      def handleReturn(reply_code, reply_text, exchange, routing_key, basic_properties, payload)
        # TODO: convert properties to a Ruby hash
        @block.call(reply_code, reply_text, exchange, routing_key, basic_properties, String.from_java_bytes(payload))
      end
    end

    # @private
    def register_consumer(consumer_tag, consumer)
      @consumers[consumer_tag] = consumer
    end

    # @private
    def unregister_consumer(consumer_tag)
      @consumers.delete(consumer_tag)
    end

    # Executes a block, catching Java exceptions RabbitMQ Java client throws and
    # transforms them to Ruby exceptions that are then re-raised.
    #
    # @private
    def converting_rjc_exceptions_to_ruby(&block)
      begin
        block.call
      rescue Exception, java.lang.Throwable => e
        Exceptions.convert_and_reraise(e)
      end
    end
  end
end
