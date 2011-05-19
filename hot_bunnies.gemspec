# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'hot_bunnies/version'


Gem::Specification.new do |s|
  s.name        = 'hot_bunnies'
  s.version     = HotBunnies::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@burtcorp.com']
  s.homepage    = ''
  s.summary     = %q{Ruby wrapper for the RabbitMQ Java driver}
  s.description = %q{A object oriented interface to RabbitMQ that uses the Java driver under the hood}

  s.rubyforge_project = 'hot_bunnies'

  s.files         = `git ls-files`.split("\n")
# s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
# s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
