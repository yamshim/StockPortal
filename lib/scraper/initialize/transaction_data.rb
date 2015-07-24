# coding: utf-8
module Scraper
  module Initialize
    module TransactionData
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
              CSV.open("#{Rails.root}/db/seeds/#{Rails.env}/csv/transaction/transactions_info_#{company_code}.csv", 'wb') do |writer|
                (1..100000).each do |page|
                  url = "http://info.finance.yahoo.co.jp/history/?code=#{company_code}&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
                  # Kernel.sleep(0.001)
                  doc = Nokogiri::HTML.parse(open(url), nil, 'utf-8')
                  transactions_info = doc.xpath('//table[@class="boardFin yjSt marB6"]/tr')[1..-1]
                  break if transactions_info.blank?
                  transactions_info.each do |transaction_info|
                    transaction_line = transaction_info.css('td').map{|td| td.text}
                    next unless transaction_line.size == 7
                    transaction_line[0] = Date.new(*transaction_line[0].split(/[^0-9]/).map{|char| char.to_i})
                    (1..6).each{|index| transaction_line[index] = transaction_line[index].delete(',').to_f}

                    if transaction_line[4] != transaction_line[6]
                      scale = (transaction_line[4] / transaction_line[6])
                      (1..4).each{|index| transaction_line[index] = (transaction_line[index] / scale).to_i}
                      transaction_line[5] = transaction_line[5].to_i
                    else
                      (1..5).each{|index| transaction_line[index] = transaction_line[index].to_i}
                    end

                    writer << transaction_line
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
            transactions_info = []
            csv_text = open("#{Rails.root}/db/seeds/#{Rails.env}/csv/transaction/transactions_info_#{company.company_code}.csv", &:read).toutf8.strip
            csv_lines = CSV.parse(csv_text)
            csv_lines.each do |csv_line|
              transaction_info = {}
              transaction_info[:date] = csv_line[0]
              transaction_info[:opening_price] = csv_line[1]
              transaction_info[:high_price] = csv_line[2]
              transaction_info[:low_price] = csv_line[3]
              transaction_info[:closing_price] = csv_line[4]
              transaction_info[:turnover] = csv_line[5]
              transactions_info << transaction_info
            end
            company.transactions.build(transactions_info).each(&:save!)
          end
        end
        true
      rescue => ex
        p ex.message
      end

    end
  end
end