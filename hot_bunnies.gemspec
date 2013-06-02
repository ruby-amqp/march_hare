# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'hot_bunnies/version'


Gem::Specification.new do |s|
  s.name        = 'hot_bunnies'
  s.version     = HotBunnies::VERSION
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg', 'Michael S. Klishin']
  s.email       = ['theo@burtcorp.com']
  s.homepage    = 'http://hotbunnies.info'
  s.summary     = %q{RabbitMQ client for JRuby built around the official RabbitMQ Java client}
  s.description = %q{RabbitMQ client for JRuby built around the official RabbitMQ Java client}

  s.rubyforge_project = 'hot_bunnies'

  s.files         = `git ls-files -- lib`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")

  s.require_paths = %w(lib)
end
