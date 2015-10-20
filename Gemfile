
#バージョン管理については後で

source 'https://rubygems.org'

gem 'rails', '4.2.3'
gem 'mysql2', '~> 0.3.18'
gem 'selenium-webdriver', '2.46.2'
gem 'whenever', require: false
gem 'pdf-reader'
gem 'unicorn', '4.9.0'
# for Logger
gem 'ltsv'
gem 'ltsvr'
gem 'fluent-logger', '~> 0.4.9'

gem 'jquery-rails'
gem 'jquery-ui-rails'

group :development, :test do
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
end

group :deployment do
  gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn' # unicornを使っている場合のみ
end

group :assets do
end




