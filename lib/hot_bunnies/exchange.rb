# encoding: utf-8

module HotBunnies
  class Exchange
    attr_reader :name, :channel
    
    def initialize(channel, name, options={})
      @channel = channel
      @name = name
      @options = {:type => :fanout, :durable => false, :auto_delete => false, :internal => false, :passive => false}.merge(options)
      declare!
    end
    
    def publish(body, options={})
      options = {:routing_key => '', :mandatory => false, :immediate => false}.merge(options)
      @channel.basic_publish(@name, options[:routing_key], options[:mandatory], options[:immediate], nil, body.to_java_bytes)
    end
    
    def delete(options={})
      @channel.exchange_delete(@name, options.fetch(:if_unused, false))
    end
    
  private
  
    def declare!
      unless @name == ''
        if @options[:passive]
        then @channel.exchange_declare_passive(@name)
        else @channel.exchange_declare(@name, @options[:type].to_s, @options[:durable], @options[:auto_delete], @options[:internal], nil)
        end
      end
    end
  end
end
