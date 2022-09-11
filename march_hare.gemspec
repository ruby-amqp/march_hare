# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'march_hare/version'


Gem::Specification.new do |s|
  s.name        = 'march_hare'
  s.version     = MarchHare::VERSION
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg', 'Michael S. Klishin']
  s.email       = ['theo@burtcorp.com', 'michael@rabbitmq.com']
  s.homepage    = 'https://github.com/ruby-amqp/march_hare'
  s.summary     = %q{RabbitMQ client for JRuby built around the official RabbitMQ Java client}
  s.description = %q{RabbitMQ client for JRuby built around the official RabbitMQ Java client}

  s.files         = `git ls-files -- lib`.split("\n")

  s.require_paths = %w(lib)
end
