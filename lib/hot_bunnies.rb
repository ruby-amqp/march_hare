# encoding: utf-8

require 'java'
require 'ext/commons-io'
require 'ext/rabbitmq-client'

require 'hot_bunnies/session'

module HotBunnies
  def self.connect(*args)
    Session.connect(*args)
  end
end

require 'hot_bunnies/channel'
require 'hot_bunnies/queue'
require 'hot_bunnies/exchange'
