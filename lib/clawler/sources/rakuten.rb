# coding: utf-8

module Clawler
  module Sources
    module Rakuten
      extend AllUtils

      def self.industry_url(industry_code, page)
        "https://www.trkd-asia.com/rakutensec/result_ja.jsp?name=&code=&all=on&sector=#{csym(:industry, industry_code).to_s.upcase}&pageNo=#{page}"
      end

      def self.company_headers(doc)
        doc.xpath('//table[@class="tbl-data-08"]/tbody/tr').map{|tr| [tr.css('td')[0].text, tr.css('td')[0].css('a').attribute('href').value.match(/ric=(.+)/)[1]]}
      end

      def self.company_url(company_code)
        "https://www.trkd-asia.com/rakutensec/quote.jsp?ric=#{company_code}&c=ja&ind=2"
      end

      def self.get_info(doc)
        doc.xpath('//table[@class="tbl-data-02"]')[0].css('td').map{|td| td.text}
      end

    end
  end
end