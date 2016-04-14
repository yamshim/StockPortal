# coding: utf-8

module Clawler
  module Sources
    module Rakuten
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'https://www.rakuten-sec.co.jp'
      end

      def self.iframe_url
        'https://www.trkd-asia.com/rakutensec'
      end

      def self.get_industry_url(industry_code, page)
        iframe_url + "/result_ja.jsp?name=&code=&all=on&sector=#{csym(:industry, industry_code).to_s.upcase}&pageNo=#{page}"
      end

      def self.get_company_headers(industry_code, page)
        industry_url = get_industry_url(industry_code, page)
        industry_doc = get_content(industry_url, :middle)
        company_headers = industry_doc.xpath('//table[@class="tbl-data-08"]/tbody/tr').map{|tr| [tr.css('td')[0].text, tr.css('td')[0].css('a').attribute('href').value.match(/ric=(.+)/)[1]]}
        company_headers
      end

      def self.get_company_line(company_header, industry_code)
        company_line = []
        company_line << c(:country, :japan) # country_code
        company_line << company_header[1].split('.')[0].to_i # company_code
        company_line << company_header[0] # name

        company_info = get_company_info(company_header)
        company_line << get_market_code(company_info[7]) # market_code
        company_line << industry_code # industry_code
        company_line << trim_to_i(company_info[8]) # trading_unit
        company_line << company_info[0] # url
        company_line << trim_to_date(company_info[5]) # established_date
        company_line << trim_to_date(company_info[6]) # listed_date
        company_line << company_info[9].split('/')[0].to_i # accounting_period
        company_line << company_info[13] # description        

        company_line
      end

      def self.get_company_info(company_header)
        company_url = get_company_url(company_header[1])
        company_doc = get_content(company_url, :middle)
        company_info = company_doc.xpath('//table[@class="tbl-data-02"]')[0].css('td').map{|td| td.text}
        company_info
      end

      def self.get_company_url(company_code)
        iframe_url + "/quote.jsp?ric=#{company_code}&c=ja&ind=2"
      end

      def self.get_market_code(market_name)
        case market_name
        when '東証1部'
          c(:market, :t_1)
        when '東証2部'
          c(:market, :t_2)
        when 'JQ'
          c(:market, :t_js)
        when 'JQ G'
          c(:market, :t_jg)
        when 'マザーズ'
          c(:market, :t_m)
        when '東証外国部'
          c(:market, :t_f)
        when '名証１部'
          c(:market, :m_1)
        when '名証２部'
          c(:market, :m_2)
        when '名証セントレックス'
          c(:market, :m_c)
        else
          nil
        end
      end

    end
  end
end