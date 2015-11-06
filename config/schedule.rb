
current_path = '/var/www/StockPortal/current'

log_path = current_path + '/log/cron.log'
error_log_path = current_path + '/log/cron_error.log'
set :output, { :standard => log_path, :error => error_log_path}

rails_runner="bundle exec rails runner -e production"

article_patrol="#{rails_runner} Clawler::Models::Article.patrol"
bracket_patrol="#{rails_runner} Clawler::Models::Bracket.patrol"
commodity_patrol="#{rails_runner} Clawler::Models::Commodity.patrol"
company_patrol="#{rails_runner} Clawler::Models::Company.patrol"
credit_deal_patrol="#{rails_runner} Clawler::Models::CreditDeal.patrol"
foreign_exchange_patrol="#{rails_runner} Clawler::Models::ForeignExchange.patrol"
transaction_patrol="#{rails_runner} Clawler::Models::Transaction.patrol"
transaction_peel="#{rails_runner} Clawler::Models::Transaction.peel"
trend_patrol="#{rails_runner} Clawler::Models::Trend.patrol"

# every :day, at: '00:30' do
#   command "#{article_patrol}"
# end

every :day, at: '21:40' do
  command "#{bracket_patrol}"
end

every :day, at: '08:50' do
  command "#{commodity_patrol}"
end

every :day, at: '22:00' do
  command "#{company_patrol}"
end

every [:wednesday], at: '22:20' do
  command "#{credit_deal_patrol}"
end

every :day, at: '21:50' do
  command "#{foreign_exchange_patrol}"
end

every [:monday, :tuesday, :wednesday, :thursday, :friday], at: '22:40' do
  command "#{transaction_patrol}"
end

every [:monday, :tuesday, :wednesday, :thursday, :friday], at: '16:00' do
  command "#{transaction_peel}"
end

every :day, at: '00:05' do
  command "#{trend_patrol}"
end

# Learn more: http://github.com/javan/whenever
