# coding: utf-8

module Scraper
  module Initialize
    module CreditDealData
      extend Scraper::Utils

      def self.to_csv

        start_date = Date.new(1980, 1, 1)
        end_date = Date.today
        company_codes = Company.select(:company_code).map(&:company_code).sort
        n = 0
        loop do
          begin
            company_codes[n..-1].each do |company_code|
              puts(company_code)
              CSV.open("#{Rails.root}/db/seeds/#{Rails.env}/csv/credit_deal/credit_deals_info_#{company_code}.csv", 'wb') do |writer|
                (1..100000).each do |page|
                  url = "http://info.finance.yahoo.co.jp/history/margin/?code=#{company_code}&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
                  # Kernel.sleep(0.001)
                  doc = Nokogiri::HTML.parse(open(url), nil, 'utf-8')
                  credit_deals_info = doc.xpath('//table[@class="boardFin yjSt marB6"]/tr')[1..-1]
                  break if credit_deals_info.blank?
                  credit_deals_info.each do |credit_deal_info|
                    credit_deal_line = credit_deal_info.css('td').map{|td| td.text}
                    credit_deal_line[0] = Date.new(*credit_deal_line[0].split(/[^0-9]/).map{|char| char.to_i})
                    (1..4).each{|index| credit_deal_line[index] = credit_deal_line[index].delete(',').to_i}
                    credit_deal_line[5] = credit_deal_line[5].delete(',').to_f

                    writer << credit_deal_line
                  end
                end
              end
              n += 1
            end
          rescue => ex
            p ex.message
          end

          break if n == company_codes.size
        end
        true #成功

      end



      def self.import
        companies = Company.all
        Company.transaction do
          companies.each do |company|
            credit_deals_info = []
            csv_text = open("#{Rails.root}/db/seeds/#{Rails.env}/csv/credit_deal/credit_deals_info_#{company.company_code}.csv", &:read).toutf8.strip
            csv_lines = CSV.parse(csv_text)
            csv_lines.each do |csv_line|
              credit_deal_info = {}
              credit_deal_info[:date] = csv_line[0]
              credit_deal_info[:selling_balance] = csv_line[1]
              credit_deal_info[:debt_balance] = csv_line[2]
              credit_deal_info[:margin_ratio] = csv_line[5]
              credit_deals_info << credit_deal_info
            end
            company.credit_deals.build(credit_deals_info).each(&:save!)
          end
        end
        true
      rescue => ex
        p ex.message
      end






    end
  end
end