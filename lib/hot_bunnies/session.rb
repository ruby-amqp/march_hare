# encoding: utf-8
require "hot_bunnies/shutdown_listener"
require "set"

module HotBunnies
  java_import com.rabbitmq.client.ConnectionFactory
  java_import com.rabbitmq.client.Connection

  # Connection to a RabbitMQ node.
  #
  # Used to open and close connections and open (create) new channels.
  #
  # @see .connect
  # @see #create_channel
  # @see #close
  # @see http://hotbunnies.info/articles/getting_started.html Getting Started guide
  # @see http://hotbunnies.info/articles/connecting.html Connecting to RabbitMQ guide
  class Session

    #
    # API
    #

    # Default reconnection interval for TCP connection failures
    DEFAULT_NETWORK_RECOVERY_INTERVAL = 5.0

    # Connects to a RabbitMQ node.
    #
    # @param [Hash] options Connection options
    #
    # @option options [String] :host ("127.0.0.1") Hostname or IP address to connect to
    # @option options [Integer] :port (5672) Port RabbitMQ listens on
    # @option options [String] :username ("guest") Username
    # @option options [String] :password ("guest") Password
    # @option options [String] :vhost ("/") Virtual host to use
    # @option options [Integer] :heartbeat (600) Heartbeat interval. 0 means no heartbeat.
    # @option options [Boolean] :tls (false) Set to true to use TLS/SSL connection. This will switch port to 5671 by default.
    #
    # @see http://hotbunnies.info/articles/connecting.html Connecting to RabbitMQ guide
    def self.connect(options={})
      cf = ConnectionFactory.new

      cf.uri                = options[:uri]          if options[:uri]
      cf.host               = hostname_from(options) if include_host?(options)
      cf.port               = options[:port].to_i    if options[:port]
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


      new(cf, options)
    end

    # @return [Array<HotBunnies::Channel>] Channels opened on this connection
    attr_reader :channels


    # @private
    def initialize(connection_factory, opts = {})
      @cf = connection_factory
      @executor_factory = opts[:executor_factory]
      @connection = self.new_connection
      @channels = JavaConcurrent::ConcurrentHashMap.new

      # should automatic recovery from network failures be used?
      @automatically_recover = if opts[:automatically_recover].nil? && opts[:automatic_recovery].nil?
                                 true
                               else
                                 opts[:automatically_recover] || opts[:automatic_recovery]
                               end
      @network_recovery_interval = opts.fetch(:network_recovery_interval, DEFAULT_NETWORK_RECOVERY_INTERVAL)
      @shutdown_hooks            = JavaConcurrent::ConcurrentSkipListSet.new

      if @automatically_recover
        self.add_automatic_recovery_hook
      end
    end

    # Opens a new channel.
    #
    # @param [Integer] (nil): Channel number. Pass nil to let HotBunnies allocate an available number
    #                         in a safe way.
    #
    # @return [HotBunnies::Channel] Newly created channel
    # @see HotBunnies::Channel
    # @see http://hotbunnies.info/articles/getting_started.html Getting Started guide
    def create_channel(n = nil)
      jc = if n
             @connection.create_channel(n)
           else
             @connection.create_channel
           end

      ch = Channel.new(self, jc)
      register_channel(ch)

      ch
    end

    # Closes connection gracefully.
    #
    # This includes shutting down consumer work pool gracefully,
    # waiting up to 5 seconds for all consumer deliveries to be
    # processed.
    def close
      @channels.select { |_, ch| ch.open? }.each do |_, ch|
        ch.close
      end

      @connection.close
    end

    # @return [Boolean] true if connection is open, false otherwise
    def open?
      @connection.open?
    end
    alias connected? open?

    # Defines a shutdown event callback. Shutdown events are
    # broadcasted when a connection is closed, either explicitly
    # or forcefully, or due to a network/peer failure.
    def on_shutdown(&block)
      sh = ShutdownListener.new(self, &block)
      @shutdown_hooks << sh

      @connection.add_shutdown_listener(sh)

      sh
    end

    # @private
    def add_automatic_recovery_hook
      fn = Proc.new do |_, signal|
        if !signal.initiated_by_application
          self.automatically_recover
        end
      end

      @automatic_recovery_hook = self.on_shutdown(&fn)
    end

    # @private
    def disable_automatic_recovery
      @connetion.remove_shutdown_listener(@automatic_recovery_hook) if @automatic_recovery_hook
    end

    # Begins automatic connection recovery (typically only used internally
    # to recover from network failures)
    def automatically_recover
      # recovering immediately makes little sense. Wait a bit first. MK.
      java.lang.Thread.sleep(@network_recovery_interval * 1000)

      @connection = self.new_connection
      self.recover_shutdown_hooks

      @channels.each do |id, ch|
        ch.automatically_recover(self, @connection)
      end
    end

    # @private
    def recover_shutdown_hooks
      @shutdown_hooks.each do |sh|
        @connection.add_shutdown_listener(sh)
      end
    end

    # Flushes the socket used by this connection.
    def flush
      @connection.flush
    end

    # @private
    def heartbeat=(n)
      @connection.heartbeat = n
    end

    # No-op, exists for better API compatibility with Bunny.
    def start
      # no-op
      #
      # This method mimics Bunny::Session#start in Bunny 0.9.
      # Without it, #method_missing will proxy the call to com.rabbitmq.client.AMQConnection,
      # which happens to have a #start method which is not idempotent.
      #
      # So we stub out #start in case someone migrating from Bunny forgets to remove
      # the call to #start. MK.
    end

    def method_missing(selector, *args)
      @connection.__send__(selector, *args)
    end

    # @return [String]
    def to_s
      "#<#{self.class.name}:#{object_id} #{@cf.username}@#{@cf.host}:#{@cf.port}, vhost=#{@cf.virtual_host}>"
    end


    #
    # Implementation
    #

    # @private
    def register_channel(ch)
      @channels[ch.channel_number] = ch
    end

    # @private
    def unregister_channel(ch)
      @channels.delete(ch.channel_number)
    end

    protected

    # @private
    def self.hostname_from(options)
      options[:host] || options[:hostname] || ConnectionFactory.DEFAULT_HOST
    end

    # @private
    def self.include_host?(options)
      !!(options[:host] || options[:hostname])
    end

    # @private
    def self.vhost_from(options)
      options[:virtual_host] || options[:vhost] || ConnectionFactory.DEFAULT_VHOST
    end

    # @private
    def self.include_vhost?(options)
      !!(options[:virtual_host] || options[:vhost])
    end

    # @private
    def self.timeout_from(options)
      options[:connection_timeout] || options[:timeout]
    end

    # @private
    def self.include_timeout?(options)
      !!(options[:connection_timeout] || options[:timeout])
    end

    # @private
    def self.username_from(options)
      options[:username] || options[:user] || ConnectionFactory.DEFAULT_USER
    end

    # @private
    def self.heartbeat_from(options)
      options[:heartbeat_interval] || options[:requested_heartbeat] || ConnectionFactory.DEFAULT_HEARTBEAT
    end

    # @private
    def self.connection_timeout_from(options)
      options[:connection_timeout_interval] || options[:connection_timeout] || ConnectionFactory.DEFAULT_CONNECTION_TIMEOUT
    end

    # @private
    def self.include_username?(options)
      !!(options[:username] || options[:user])
    end

    # @private
    def self.password_from(options)
      options[:password] || options[:pass] || ConnectionFactory.DEFAULT_PASS
    end

    # @private
    def self.include_password?(options)
      !!(options[:password] || options[:pass])
    end

    # @private
    def self.include_heartbeat?(options)
      !!(options[:heartbeat_interval] || options[:requested_heartbeat] || options[:heartbeat])
    end

    # @private
    def self.include_connection_timeout?(options)
      !!(options[:connection_timeout_interval] || options[:connection_timeout])
    end

    # Executes a block, catching Java exceptions RabbitMQ Java client throws and
    # transforms them to Ruby exceptions that are then re-raised.
    #
    # @private
    def converting_rjc_exceptions_to_ruby(&block)
      begin
        block.call
      rescue java.net.ConnectException => e
        raise ConnectionRefused.new("Connection to #{@cf.host}:#{@cf.port} refused")
      rescue java.net.UnknownHostException => e
        raise ConnectionRefused.new("Connection to #{@cf.host}:#{@cf.port} refused: host unknown")
      rescue com.rabbitmq.client.PossibleAuthenticationFailureException => e
        raise PossibleAuthenticationFailureError.new(@cf.username, @cf.virtual_host, @cf.password.bytesize)
      end
    end

    # @private
    def new_connection
      converting_rjc_exceptions_to_ruby do
        if @executor_factory
          @cf.new_connection(@executor_factory.call)
        else
          @cf.new_connection
        end
      end
    end
  end
end
