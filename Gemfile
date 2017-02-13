source "https://rubygems.org"

gemspec

gem 'rake', ">= 10.0.0"

group :test do
  gem "rspec", "~> 3.5"
end

group :development do
  gem "yard"
  # JRuby-friendly Markdown renderer
  gem "kramdown",  :platform => :jruby
  gem "redcarpet", :platform => :mri

  gem "rabbitmq_http_api_client", "~> 1.8.0"
end
