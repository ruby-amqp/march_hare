# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'

require 'carrot_cake/version'
require 'carrot_cake/exceptions'
require 'carrot_cake/session'

# CarrotCake is a JRuby client for RabbitMQ built on top of the official Java client.
#
# @see CarrotCake.connect
# @see CarrotCake::Session
# @see CarrotCake::Channel
module CarrotCake
  # Delegates to {CarrotCake::Session.connect}
  # @see CarrotCake::Session.connect
  def self.connect(*args)
    Session.connect(*args)
  end
end

# Backwards compatibility
# @private
Hotbunnies = CarrotCake
# Backwards compatibility
# @private
HotBunnies = CarrotCake

require 'carrot_cake/channel'
require 'carrot_cake/queue'
require 'carrot_cake/exchange'
