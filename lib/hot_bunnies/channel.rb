# encoding: utf-8

module HotBunnies
  class Channel

    attr_reader :session

    def initialize(session, delegate)
      @connection = session
      @delegate   = delegate
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
      @connection.unregister_channel(self)

      v
    end


    # @group Exchanges

    def exchange(name, options={})
      exchange = Exchange.new(self, name, options)
      exchange.declare!
      exchange
    end

    def fanout(name, opts = {})
      Exchange.new(self, opts.merge(:type => "fanout"))
    end

    def direct(name, opts = {})
      Exchange.new(self, opts.merge(:type => "direct"))
    end

    def topic(name, opts = {})
      Exchange.new(self, opts.merge(:type => "topic"))
    end

    def headers(name, opts = {})
      Exchange.new(self, opts.merge(:type => "headers"))
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
      Queue.new(self, name, options)
    end

    def queue_declare(name, durable, exclusive, auto_delete, arguments = {})
      @delegate.queue_declare(name, durable, exclusive, auto_delete, arguments)
    end

    def queue_declare_passive(name)
      @delegate.queue_declare_passive(name)
    end

    def queue_delete(name, if_empty = false, if_unused = false)
      @delegate.queue_delete(name, if_empty, if_unused)
    end

    def queue_bind(queue, exchange, routing_key, arguments = nil)
      @delegate.queue_bind(queue, exchange, routing_key, arguments)
    end

    def queue_unbind(queue, exchange, routing_key, arguments = nil)
      @delegate.queue_unbind(queue, exchange, routing_key, arguments)
    end

    def queue_purge(name)
      @delegate.queue_purge(name)
    end

    # @endgroup


    # @group basic.*

    def basic_publish(exchange, routing_key, mandatory, immediate, properties, body)
      @delegate.basic_publish(exchange, routing_key, mandatory, immediate, properties, body)
    end

    def basic_get(queue, auto_ack)
      @delegate.basic_get(queue, auto_ack)
    end

    def basic_consume(queue, auto_ack, consumer)
      @delegate.basic_consume(queue, auto_ack, consumer)
    end

    def basic_qos(prefetch_count)
      @delegate.basic_qos(prefetch_count)
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
      basic_ack(delivery_tag, multiple)
    end
    alias acknowledge ack

    def reject(delivery_tag, requeue = false)
      basic_reject(delivery_tag, requeue)
    end

    def nack(delivery_tag, multiple = false, requeue = false)
      basic_nack(delivery_tag, multiple, requeue)
    end

    def basic_recover(requeue = true)
      @delegate.basic_recover(requeue)
    end

    def basic_recover_async(requeue = true)
      @delegate.basic_recover_async(requeue)
    end

    # @endgroup


    def confirm_select
      @delegate.confirm_select
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
        @delegate.wait_for_confirms(timeout)
      else
        @delegate.wait_for_confirms
      end
    end

    def next_publisher_seq_no
      @delegate.next_publisher_seq_no
    end

    def tx_select
      @delegate.tx_select
    end

    def tx_commit
      @delegate.tx_commit
    end

    def tx_rollback
      @delegate.tx_rollback
    end

    def channel_flow(active)
      @delegate.channel_flow(active)
    end


    def on_return(&block)
      self.set_return_listener(block)
    end

    def method_missing(selector, *args)
      @delegate.__send__(selector, *args)
    end

  end
end
