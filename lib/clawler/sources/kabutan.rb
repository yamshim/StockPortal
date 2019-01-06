# coding: utf-8

module Clawler
  module Sources
    module Kabutan
      extend AllUtils
      extend Clawler::Utils
      EXCEPTIONAL_COMPANY_CODES = [8421, 8682]

      def self.home_url
        'https://kabutan.jp'
      end

      # ---company---

      def self.get_industry_url(industry_code, page)
        home_url + "/themes/?industry=#{industry_code + 1}&market=0&stc=&stm=0&page=#{page}"
      end

      def self.get_company_codes(industry_code, page)
        industry_url = get_industry_url(industry_code, page)
        industry_doc = get_content(industry_url, :middle)
        company_codes = industry_doc.xpath('//table[@class="stock_table"]/tr/descendant::td[1]').map{|td| td.text.to_i}
        company_codes
      end

      def self.get_company_line(company_code, industry_code)
        return nil if EXCEPTIONAL_COMPANY_CODES.include?(company_code) # kabutanでは信金中央金庫は銀行業扱いだが除外
        # company_line[0] = country_code
        # company_line[1] = company_code
        # company_line[2] = name
        # company_line[3] = market_code
        # company_line[4] = industry_code
        # company_line[5] = trading_unit
        # company_line[6] = url
        # company_line[7] = established_data
        # company_line[8] = listed_date
        # company_line[9] = accounting_period
        # company_line[10] = description
        company_line = []
        # kabutanでname, market_name, industry_name, trading_unit, url, descriptionを集める
        company_info_kabutan = get_company_info(company_code)
        company_line << c(:country, :japan) # country_code
        company_line << company_code # company_code
        company_line << company_info_kabutan[0] # name
        company_line << get_market_code(company_info_kabutan[1]) # market_code
        if c(:industry, industry_code) =~ %r|#{company_info_kabutan[2]}| # この可能性はあり得る？ industry_codeのバリデーション
          company_line << industry_code #industry_code
        else
          return nil
        end
        company_line << trim_to_i(company_info_kabutan[3]) # trading_unit
        company_line << company_info_kabutan[4] # url
                
        # yahooでstablished_date, listed_date, accounting_periodを集める
        company_info_yahoo = Clawler::Sources::Yahoo.get_company_info(company_code)
        company_line << trim_to_date(company_info_yahoo[0]) # established_data
        company_line << trim_to_date(company_info_yahoo[1]) # listed_date
        company_line << trim_to_i(company_info_yahoo[2]) # accounting_period
        company_line << (company_info_kabutan[5] + '\n' + company_info_yahoo[3]) # description
        company_line
      end

      def self.get_company_info(company_code)
        company_info = []
        company_url = get_company_url(company_code)
        company_doc = get_content(company_url, :middle)
        company_info << company_doc.title.split(/\s/)[0].strip # name
        company_info << company_doc.xpath('//div[@id="stockinfo_i1"]').css('span[@class="market"]').text.strip # market_name
        company_info << company_doc.xpath('//div[@id="stockinfo_i2"]').css('a').text.strip # industry_name
        company_info << company_doc.xpath('//div[@id="stockinfo_i2"]').css('dd').text.strip # trading_unit
        company_info += company_doc.xpath('//div[@class="company_block"]/table').css('td')[1..2].map{|td| td.text.strip} # url, description
        themes = company_doc.xpath('//div[@class="company_block"]/table').css('td')[4].text.gsub(/(\s|\n)+/, '***').split('***')[1..-1] # 関連テーマ
        company_info # ["ピアラ", "東証Ｍ", "サービス業", "100株", "https://piala.co.jp/", "電子商取引(EC)事業者向けに新規顧客獲得などの支援事業を展開する。"]
      end

      def self.get_company_url(company_code)
        "https://kabutan.jp/stock/?code=#{company_code}"
      end

      def self.get_market_code(market_name)
        case market_name
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
        else
          nil
        end
      end

      # ---transaction---

      def self.get_some_info(company_code, line_date)
        transaction_info = []
        company_url = get_company_url(company_code)
        transaction_doc = get_content(company_url, :short)
        date = transaction_doc.xpath('//div[@id="kobetsu_left"]/h2').css('time').attribute('datetime').value
        return [nil, nil] if date != line_date.to_s
        transaction_info << trim_to_f(transaction_doc.xpath('//div[@id="kobetsu_left"]/table[2]').css('tr/td')[2].text.strip) # vwap
        transaction_info << trim_to_i(transaction_doc.xpath('//div[@id="kobetsu_left"]/table[2]').css('tr/td')[3].text.strip) # tick_count
        transaction_info
      end

    end
  end
end