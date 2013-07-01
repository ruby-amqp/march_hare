# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'

require 'hot_bunnies/version'
require 'hot_bunnies/exceptions'
require 'hot_bunnies/session'

module HotBunnies
  # Delegates to {HotBunnies::Session.connect}
  def self.connect(*args)
    Session.connect(*args)
  end
end
Hotbunnies = HotBunnies

require 'hot_bunnies/channel'
require 'hot_bunnies/queue'
require 'hot_bunnies/exchange'
