module HotBunnies
  import com.rabbitmq.client.ConnectionFactory
  import com.rabbitmq.client.Connection

  class Session

    #
    # API
    #

    def self.connect(options={})
      cf = ConnectionFactory.new

      cf.uri                = options[:uri]          if options[:uri]
      cf.host               = hostname_from(options) if include_host?(options)
      cf.port               = options[:port]         if options[:port]
      cf.virtual_host       = vhost_from(options)    if include_vhost?(options)
      cf.connection_timeout = timeout_from(options)  if include_timeout?(options)
      cf.username           = username_from(options) if include_username?(options)
      cf.password           = password_from(options) if include_password?(options)

      cf.requested_heartbeat = heartbeat_from(options)          if include_heartbeat?(options)
      cf.connection_timeout  = connection_timeout_from(options) if include_connection_timeout?(options)

      tls = (options[:ssl] || options[:tls])
      case tls
      when true then
        cf.use_ssl_protocol
      when String then
        if options[:trust_manager]
          cf.use_ssl_protocol(tls, options[:trust_manager])
        else
          cf.use_ssl_protocol(tls)
        end
      end

      new(cf)
    end


    def initialize(connection_factory)
      @connection = connection_factory.new_connection
    end


    def create_channel(n = nil)
      jc = if n
             @connection.create_channel(n)
           else
             @connection.create_channel
           end

      Channel.wrap(jc)
    end

    def close
      @connection.close
    end

    def flush
      @connection.flush
    end

    def heartbeat=(n)
      @connection.heartbeat = n
    end

    def method_missing(selector, *args)
      @connection.__send__(selector, *args)
    end


    protected

    def self.hostname_from(options)
      options[:host] || options[:hostname] || ConnectionFactory.DEFAULT_HOST
    end

    def self.include_host?(options)
      !!(options[:host] || options[:hostname])
    end

    def self.vhost_from(options)
      options[:virtual_host] || options[:vhost] || ConnectionFactory.DEFAULT_VHOST
    end

    def self.include_vhost?(options)
      !!(options[:virtual_host] || options[:vhost])
    end

    def self.timeout_from(options)
      options[:connection_timeout] || options[:timeout]
    end

    def self.include_timeout?(options)
      !!(options[:connection_timeout] || options[:timeout])
    end

    def self.username_from(options)
      options[:username] || options[:user] || ConnectionFactory.DEFAULT_USER
    end

    def self.heartbeat_from(options)
      options[:heartbeat_interval] || options[:requested_heartbeat] || ConnectionFactory.DEFAULT_HEARTBEAT
    end

    def self.connection_timeout_from(options)
      options[:connection_timeout_interval] || options[:connection_timeout] || ConnectionFactory.DEFAULT_CONNECTION_TIMEOUT
    end

    def self.include_username?(options)
      !!(options[:username] || options[:user])
    end

    def self.password_from(options)
      options[:password] || options[:pass] || ConnectionFactory.DEFAULT_PASS
    end

    def self.include_password?(options)
      !!(options[:password] || options[:pass])
    end

    def self.include_heartbeat?(options)
      !!(options[:heartbeat_interval] || options[:requested_heartbeat] || options[:heartbeat])
    end

    def self.include_connection_timeout?(options)
      !!(options[:connection_timeout_interval] || options[:connection_timeout])
    end
  end
end
