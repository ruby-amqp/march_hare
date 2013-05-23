# encoding: utf-8

module HotBunnies
  module Channel
    def queue(name, options={})
      Queue.new(self, name, options)
    end

    def exchange(name, options={})
      exchange = Exchange.new(self, name, options)
      exchange.declare!
      exchange
    end

    def default_exchange
      self.exchange("", :durable => true, :auto_delete => false, :type => "direct")
    end

    def qos(options={})
      if options.size == 1 && options[:prefetch_count]
      then basic_qos(options[:prefetch_count])
      else basic_qos(options.fetch(:prefetch_size, 0), options.fetch(:prefetch_count, 0), options.fetch(:global, false))
      end
    end

    def prefetch=(n)
      qos(:prefetch_count => n)
    end

    def on_return(&block)
      self.set_return_listener(block)
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
  end
end
