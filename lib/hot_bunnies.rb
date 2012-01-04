# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'


module HotBunnies
  import com.rabbitmq.client.ConnectionFactory
  import com.rabbitmq.client.Connection
  import com.rabbitmq.client.Channel
  import com.rabbitmq.client.DefaultConsumer
  import com.rabbitmq.client.QueueingConsumer

  import com.rabbitmq.client.AMQP

  def self.connect(options={})
    cf = ConnectionFactory.new

    cf.uri                = options[:uri]          if options[:uri]
    cf.host               = hostname_from(options) if include_host?(options)
    cf.port               = options[:port]         if options[:port]
    cf.virtual_host       = vhost_from(options)    if include_vhost?(options)
    cf.connection_timeout = timeout_from(options)  if include_timeout?(options)
    cf.username           = username_from(options) if include_username?(options)
    cf.password           = password_from(options) if include_password?(options)

    cf.new_connection
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

  def self.include_username?(options)
    !!(options[:username] || options[:user])
  end

  def self.password_from(options)
    options[:password] || options[:pass] || ConnectionFactory.DEFAULT_PASS
  end

  def self.include_password?(options)
    !!(options[:password] || options[:pass])
  end
end

require 'hot_bunnies/channel'
require 'hot_bunnies/queue'
require 'hot_bunnies/exchange'
