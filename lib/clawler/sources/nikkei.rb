# coding: utf-8

module Clawler
  module Sources
    module Nikkei
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://www.nikkei.com'
      end

      def self.get_trends_url(page)
        "http://www.nikkei.com/news/category/?bn=#{1 + (page - 1) * 20}"
      end

      def self.get_urls(page)
        trends_url = Clawler::Sources::Nikkei.get_trends_url(page)
        trends_doc = get_content(trends_url, :short)
        urls = []
        urls += trends_doc.xpath('//div[@class="cmn-top_news cmn-clearfix cmn-middle_mark"]').css('a').map{|a| home_url + a.attribute('href').value}
        urls += trends_doc.xpath('//li[@class="cmnc-article cmn-clearfix cmn-small_mark"]').css('a').map{|a| home_url + a.attribute('href').value}
        urls.uniq
      end

      def self.get_info(url)
        url_doc = get_content(url, :short)
        date = trim_to_date(url_doc.xpath('//dd[@class="cmnc-publish"]').text.split(' ')[0])
        texts = []
        text = ''
        url_doc.xpath('//div[@class="cmn-article_text JSID_key_fonttxt"]/p').each do |p|
          p.children.each do |child|
            text += child.text.gsub(/\s/, '').gsub(/\/dx\/async\/.+/, '').gsub(/<!--.+-->/, '').gsub(/\(c\).+/, '').gsub(/〔.+〕/, '').gsub(/【.+】/, '')
            if text.bytesize > 500
              texts << text
              text = ''
            end
          end
        end
        [date, texts]
      end

    end
  end
end