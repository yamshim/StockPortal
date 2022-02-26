
#バージョン管理については後で

source 'https://rubygems.org'

gem 'rails', '4.2.3'
gem 'mysql2', '~> 0.3.18'
gem 'selenium-webdriver', '2.46.2'
gem 'whenever', require: false
gem 'pdf-reader'
gem 'unicorn', '4.9.0'
gem 'gmail', '0.6.0'
gem 'extractcontent', github: 'mono0x/extractcontent'
gem 'webdrivers', '2.4.0'
gem 'nokogiri', '1.13.3'
gem 'net-ssh', '3.0.1'
gem 'parallel'

# for Logger
gem 'ltsv'
gem 'ltsvr'
gem 'fluent-logger', '~> 0.4.9'

# for assets
gem 'jquery-rails', '4.0.5'
gem 'jquery-ui-rails', '5.0.5'
gem 'uglifier'

# for Linux
gem 'libv8'
gem 'execjs', '~> 2.6.0'
gem 'therubyracer', '~> 0.12.2', :platforms => :ruby

group :development, :test do
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
end

group :deployment do
  gem 'capistrano', '3.11.0'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn' # unicornを使っている場合のみ
end

group :assets do
end




