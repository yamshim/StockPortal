
current_path = '/var/www/StockPortal/current'

log_path = current_path + '/log/cron.log'
error_log_path = current_path + '/log/cron_error.log'
set :output, { :standard => log_path, :error => error_log_path}

cd_path="cd #{current_path}"
rails_runner="bundle exec rails runner -e production"

article_patrol="#{rails_runner} Clawler::Models::Article.patrol"
bracket_patrol="#{rails_runner} Clawler::Models::Bracket.patrol"
commodity_patrol="#{rails_runner} Clawler::Models::Commodity.patrol"
company_patrol="#{rails_runner} Clawler::Models::Company.patrol"
credit_deal_patrol="#{rails_runner} Clawler::Models::CreditDeal.patrol"
foreign_exchange_patrol="#{rails_runner} Clawler::Models::ForeignExchange.patrol"
proxy_patrol="#{rails_runner} Clawler::Files::Proxy.patrol"
transaction_patrol="#{rails_runner} Clawler::Models::Transaction.patrol"
chart_patrol="#{rails_runner} Clawler::Files::Chart.patrol"
trend_patrol="#{rails_runner} Clawler::Models::Trend.patrol"

# every :day, at: '00:30' do
#   command "#{cd_path} && #{article_patrol}"
# end

# every :day, at: '21:00' do
#   command "#{cd_path} && #{bracket_patrol}"
# end

# every :day, at: '08:55' do
#   command "#{cd_path} && #{commodity_patrol}"
# end

every :day, at: '18:00' do
  command "#{cd_path} && #{company_patrol}"
end

every [:wednesday, :friday], at: '20:00' do
  command "#{cd_path} && #{credit_deal_patrol}"
end

every :day, at: '19:00' do
  command "#{cd_path} && #{foreign_exchange_patrol}"
end

# every :day, at: '09:30' do
#   command "#{cd_path} && #{proxy_patrol}"
# end

every [:monday, :tuesday, :wednesday, :thursday, :friday], at: '18:30' do
  command "#{cd_path} && #{transaction_patrol}"
end

# every [:monday, :tuesday, :wednesday, :thursday, :friday], at: '15:40' do
#   command "#{cd_path} && #{chart_patrol}"
# end

# every :day, at: '00:05' do
#   command "#{cd_path} && #{trend_patrol}"
# end

# Learn more: http://github.com/javan/whenever
