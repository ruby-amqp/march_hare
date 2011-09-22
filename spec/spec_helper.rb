# encoding: utf-8

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bundler'
Bundler.setup(:default, :test)

case RUBY_VERSION
when "1.8.7" then
  class Array
    alias sample choice
  end
end


require "hot_bunnies"