# encoding: utf-8

require "hot_bunnies/juc"
require "hot_bunnies/metadata"
require "hot_bunnies/consumers"

module HotBunnies
  class Queue
    attr_reader :name, :channel

    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:durable => false, :exclusive => false, :auto_delete => false, :passive => false, :arguments => Hash.new}.merge(options)
      declare!
    end

    def bind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_bind(@name, exchange_name, options.fetch(:routing_key, ''), options[:arguments])
    end

    def unbind(exchange, options={})
      exchange_name = if exchange.respond_to?(:name) then exchange.name else exchange.to_s end
      @channel.queue_unbind(@name, exchange_name, options.fetch(:routing_key, ''))
    end

    def delete
      @channel.queue_delete(@name)
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

    def subscribe(opts = {}, &block)
      consumer = if opts[:block] || opts[:blocking]
                   BlockingCallbackConsumer.new(@channel, opts[:buffer_size], block)
                 else
                   AsyncCallbackConsumer.new(@channel, block, opts.fetch(:executor, JavaConcurrent::Executors.new_single_thread_executor))
                 end

      @consumer_tag     = @channel.basic_consume(@name, !(opts[:ack] || opts[:manual_ack]), consumer)
      consumer.consumer_tag = @consumer_tag

      @default_consumer = consumer
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


    private

    def declare!
      response = if @options[:passive]
                 then @channel.queue_declare_passive(@name)
                 else @channel.queue_declare(@name, @options[:durable], @options[:exclusive], @options[:auto_delete], @options[:arguments])
                 end
      @name = response.queue
    end
  end # Queue
end # HotBunnies
