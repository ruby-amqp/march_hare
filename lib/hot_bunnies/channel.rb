# encoding: utf-8

module HotBunnies
  module Channel
    def queue(name, options={})
      Queue.new(self, name, options)
    end

    def exchange(name, options={})
      exchange = Exchange.new(self, name, options)
      if block_given?
        yield(exchange, exchange.declare!)
      else
        exchange.declare!
      end
      exchange
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
  end
end
