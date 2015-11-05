# coding: utf-8

module Clawler
  module Sources
    module Kabutan
      extend AllUtils
      extend Clawler::Utils
      EXCEPTIONAL_COMPANY_CODES = [8421, 8682]

      def self.home_url
        'http://kabutan.jp'
      end

      # ---company---

      def self.get_industry_url(industry_code, page)
        "http://kabutan.jp/themes/?industry=#{industry_code + 1}&market=0&stc=&stm=0&page=#{page}"
      end

      def self.get_company_codes(industry_code, page)
        industry_url = get_industry_url(industry_code, page)
        industry_doc = get_content(industry_url, :middle)
        company_codes = industry_doc.xpath('//table[@class="stock_table"]/tr/descendant::td[1]').map{|td| td.text.to_i}
        company_codes
      end

      def self.get_company_line(company_code, industry_code)
        company_line = []
        return nil if EXCEPTIONAL_COMPANY_CODES.include?(company_code) # kabutanでは信金中央金庫は銀行業扱いだが除外
        company_line << c(:country, :japan) # country_code
        company_line << company_code # company_code

        company_info1, company_info2, company_info3 = get_company_info(company_code) 
        company_line << company_info1[2] # name
        company_line << get_market_code(company_info1[3]) # market_code

        if c(:industry, industry_code) =~ %r|#{company_info2[1].text.strip}|
          company_line << industry_code #industry_code
        else
          return nil
        end
        company_line << trim_to_i(company_info2[2].text) # trading_unit

        company_line << company_info3[0].text # url
                
        # yahooで基本情報を集める
        company_info4 = Clawler::Sources::Yahoo.get_company_info(company_code)
        company_line << trim_to_date(company_info4[9]) # established_data
        company_line << trim_to_date(company_info4[11]) # listed_date
        company_line << trim_to_i(company_info4[12]) # accounting_period
        company_line << (company_info3[1].text + '\n' + company_info4[1]) # description
        company_line
      end

      def self.get_company_info(company_code)
        company_url = get_company_url(company_code)
        company_doc = get_content(company_url, :middle)
        company_info1 = company_doc.xpath('//table[@class="kobetsu_data_table1"]').css('tr')[0].text.gsub(/(\r\n)+/, '-').split('-')
        company_info2 = company_doc.xpath('//table[@class="kobetsu_data_table2"]').css('td')
        company_info3 = company_doc.xpath('//ul').css('dd')
        [company_info1, company_info2, company_info3]
      end

      def self.get_company_url(company_code)
        "http://kabutan.jp/stock/?code=#{company_code}"
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

      def self.get_vwap(company_code)
        company_url = get_company_url(company_code)
        company_doc = get_content(company_url, :short)
        company_info = company_doc.xpath('//table[@class="stock_st_table"]/tr/td').map(&:text)
        company_info.delete('')
        if company_info[0].split(/[^0-9]/).map(&:to_i) == [Date.today.month, Date.today.day]
          trim_to_f(company_info[18])
        else
          nil
        end
      end

    end
  end
end