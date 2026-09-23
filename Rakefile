# encoding: utf-8

require 'bundler'


Bundler::GemHelper.install_tasks

namespace :jars do
  desc 'Rebuild lib/ext/rabbitmq-client-netty-shaded.jar via Maven (run after bumping amqp-client or Netty versions in pom.xml)'
  task :build do
    sh 'mvn package -q'
    puts 'Built lib/ext/rabbitmq-client-netty-shaded.jar'
  end
end
