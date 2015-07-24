# coding: utf-8

module Scraper
  module Initialize
    module ForeignExchangeData
      extend Scraper::Utils


      def self.to_csv
        start_date = Date.new(1980, 1, 1)
        end_date = Date.today

        n = 0
        loop do
          begin
            ckeys(:foreign_exchange)[n..-1].each do |currency|
              CSV.open("#{Rails.root}/db/seeds/development/csv/foreign_exchange/foreign_exchanges_info_#{currency}.csv", 'wb') do |writer|
                (1..100000).each do |page|
                  url = "http://info.finance.yahoo.co.jp/history/?code=#{currency.upcase}%3DX&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
                  doc = Nokogiri::HTML.parse(open(url), nil, 'utf-8')
                  foreign_exchanges_info = doc.xpath('//table[@class="boardFin yjSt marB6"]/tr')[1..-1]
                  break if foreign_exchanges_info.blank?
                  foreign_exchanges_info.each do |foreign_exchange_info|
                    foreign_exchange_line = foreign_exchange_info.css('td').map{|td| td.text}
                    foreign_exchange_line[0] = Date.new(*foreign_exchange_line[0].split(/[^0-9]/).map{|char| char.to_i})
                    (1..4).each{|index| foreign_exchange_line[index] = foreign_exchange_line[index].delete(',').to_f}

                    writer << foreign_exchange_line
                  end
                end
              end
              n += 1
            end
          rescue => ex
            p ex.message
          end
          break if n == ckeys(:foreign_exchange).size
        end
        true
      end


      def self.import

        ForeignExchange.transaction do
          ckeys(:foreign_exchange).each do |currency|
            foreign_exchanges = []
            csv_text = open("#{Rails.root}/db/seeds/development/csv/foreign_exchange/foreign_exchanges_info_#{currency.upcase}.csv", &:read).toutf8.strip
            csv_lines = CSV.parse(csv_text)
            csv_lines.each do |csv_line|
              foreign_exchange_info = {}
              foreign_exchange_info[:date] = csv_line[0]
              foreign_exchange_info[:opening_price] = csv_line[1]
              foreign_exchange_info[:high_price] = csv_line[2]
              foreign_exchange_info[:low_price] = csv_line[3]
              foreign_exchange_info[:closing_price] = csv_line[4]
              foreign_exchange_info[:currency_code] = c(:foreign_exchange, currency.to_sym)

              foreign_exchanges << ForeignExchange.new(foreign_exchange_info)
            end
            foreign_exchanges.each(&:save)
          end
          true
        end
      rescue => ex
        p ex.message
      end



    end
  end
end