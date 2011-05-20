# encoding: utf-8

module HotBunnies
  class Exchange
    attr_reader :name
    
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:type => :fanout, :durable => false, :auto_delete => false, :internal => false}.merge(options)
      declare!
    end
    
    def publish(body, options={})
      options = {:routing_key => '', :mandatory => false, :immediate => false}.merge(options)
      @channel.basic_publish(@name, options[:routing_key], options[:mandatory], options[:immediate], nil, body.to_java.bytes)
    end
    
    def delete(options={})
      @channel.exchange_delete(@name, options.fetch(:if_unused, false))
    end
    
  private
  
    def declare!
      unless @name == ''
        @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:internal], nil)
      end
    end
  end
end
