# coding: utf-8
module Scraper
  module Initialize
    module CompanyData
      extend Scraper::Utils

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける

      def self.to_csv
        industry_codes = cvals(:industry)
        n = 0
        loop do
          begin
            industry_codes[n..-1].each do |industry_code|
              puts csym(:industry, industry_code)
              CSV.open("#{Rails.root}/db/seeds/#{Rails.env}/csv/company/companies_info_#{csym(:industry, industry_code)}.csv", 'wb') do |writer|
                (1..10000).each do |page|

                  url_industry = "http://kabutan.jp/themes/?industry=#{industry_code + 1}&market=0&stc=&stm=0&page=#{page}"
                  Kernel.sleep(0.0001)
                  doc_industry = Nokogiri::HTML.parse(open(url_industry), nil, 'utf-8')

                  company_codes = doc_industry.xpath('//table[@class="stock_table"]/tr/descendant::td[1]').map{|td| td.text}
                  break if company_codes.empty?
                  company_codes.each do |company_code|

                    next if ['8421', '8682'].include?(company_code) #kabutanでは信金中央金庫は銀行業扱いだが除外
                    company_info = []
                    company_info << c(:country, :japan) #country_code
                    company_info << company_code.to_i #company_code

                    #kabutanで基本情報を集める
                    url_fundamental_kabutan = "http://kabutan.jp/stock/?code=#{company_code}"
                    Kernel.sleep(0.0001)
                    doc_fundamental_kabutan = Nokogiri::HTML.parse(open(url_fundamental_kabutan), nil, 'utf-8')

                    info1 = doc_fundamental_kabutan.xpath('//table[@class="kobetsu_data_table1"]').css('tr')[0].text.gsub(/(\r\n)+/, '-').split('-')
                    company_info << info1[2] #name
                    company_info << case info1[3] #market_code
                    when "東証１"
                      c(:market, :t_1)
                    when "東証２"
                      c(:market, :t_2)
                    when "ＪＱ"
                      c(:market, :t_js)
                    when "ＪＱＧ"
                      c(:market, :t_jg)
                    when "東証Ｍ"
                      c(:market, :t_m)
                    when "東証外"
                      c(:market, :t_f)
                    when "札証"
                      c(:market, :s)
                    when "札証Ａ"
                      c(:market, :s_a)
                    when "名証１"
                      c(:market, :m_1)
                    when "名証２"
                      c(:market, :m_2)
                    when "名証Ｃ"
                      c(:market, :m_c)
                    when "福証"
                      c(:market, :f)
                    when "福証Ｑ"
                      c(:market, :f_q)
                    end

                    info2 = doc_fundamental_kabutan.xpath('//table[@class="kobetsu_data_table2"]').css('td')
                    c(:industry, info2[1].text.strip) ? (company_info << c(:industry, info2[1].text.strip)) : next #industry_code
                    company_info << info2[2].text.gsub(/[^0-9]/, '').to_i #trading_unit

                    info3 = doc_fundamental_kabutan.xpath('//ul').css('dd')
                    company_info << info3[0].text #url
                
                    #yahooで基本情報を集める
                    url_fundamental_yahoo = "http://profile.yahoo.co.jp/fundamental/?s=#{company_code}"
                    Kernel.sleep(0.0001)
                    doc_fundamental_yahoo = Nokogiri::HTML.parse(open(url_fundamental_yahoo), nil, 'utf-8')

                    info4 = doc_fundamental_yahoo.css('table[1] > tr').map{|tr| tr.text.split("\n")[2]}
                    company_info << Date.new(*info4[9].split(/[^0-9]/).map{|char| char.to_i}) #established_data
                    company_info << Date.new(*info4[11].split(/[^0-9]/).map{|char| char.to_i}) #listed_date
                    company_info << info4[12].gsub(/[^0-9]/, '').to_i #accounting_period
                    company_info << (info3[1].text + '\n' + info4[1]) #description
              
          
                    writer << company_info
                  end
                end
              end
              n += 1
            end
          rescue => ex
            p ex.message
          end
          break if n == industry_codes.size
        end
        true #成功
      end

      def self.import
        companies = []
        existing_companies = Company.select(:company_code).map(&:company_code).sort
        industry_codes = cvals(:industry)

        industry_codes.each do |industry_code|
          csv_text = open("#{Rails.root}/db/seeds/#{Rails.env}/csv/company/companies_info_#{csym(:industry, industry_code)}.csv", &:read).toutf8.strip
          csv_lines = CSV.parse(csv_text)
          csv_lines.each do |csv_line|
            unless existing_companies.include?(csv_line[1].to_i)
              company_info = {}
              company_info[:country_code] = csv_line[0].to_i
              company_info[:company_code] = csv_line[1].to_i
              company_info[:name] = csv_line[2]
              company_info[:market_code] = csv_line[3].to_i
              company_info[:industry_code] = csv_line[4].to_i
              company_info[:trading_unit] = csv_line[5].to_i
              company_info[:url] = csv_line[6]
              company_info[:established_date] = csv_line[7]
              company_info[:listed_date] = csv_line[8]
              company_info[:accounting_period] = csv_line[9].to_i
              company_info[:description] = csv_line[10]

              companies << Company.new(company_info)
            end
          end
        end

        begin
          Company.transaction{companies.each(&:save!)}
        rescue => ex
          p ex.message
        end
        true #成功
      end


    end
  end
end






