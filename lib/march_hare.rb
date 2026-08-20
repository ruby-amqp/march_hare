# encoding: utf-8

require 'java' unless defined?(TruffleRuby)

# Java client logging depends on SLF4J
require 'ext/slf4j-api'
require 'ext/slf4j-simple'

# Modern RabbitMQ Java client depends on Netty
require 'ext/netty-common'
require 'ext/netty-buffer'
require 'ext/netty-resolver'
require 'ext/netty-transport'
require 'ext/netty-codec-base'
require 'ext/netty-handler'

require 'ext/rabbitmq-client'

require 'march_hare/version'
require 'march_hare/exceptions'
require 'march_hare/session'

# MarchHare is a JRuby client for RabbitMQ built on top of the official Java client.
#
# @see MarchHare.connect
# @see MarchHare::Session
# @see MarchHare::Channel
module MarchHare
  # Delegates to {MarchHare::Session.connect}
  # @see MarchHare::Session.connect
  def self.connect(*args)
    Session.connect(*args)
  end
end

# Backwards compatibility
# @private
Hotbunnies = MarchHare
# Backwards compatibility
# @private
HotBunnies = MarchHare

require 'march_hare/channel'
require 'march_hare/queue'
require 'march_hare/exchange'
