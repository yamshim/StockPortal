# coding: utf-8

module Clawler
  module Sources
    module Google
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://www.google.co.jp'
      end

      def self.get_articles_url(word, page)
        home_url + "/search?q=#{URI.encode(word)}&tbm=nws&start=#{(page - 1) * 10}"
      end

      def self.get_articles_info(company_name, page)
        articles_url = get_articles_url(company_name, page)
        articles_doc = get_content(articles_url, :long)
        articles_info = articles_doc.xpath('//li[@class="g"]')
        articles_info
      end

      def self.get_article_lines(articles_info, company_name)
        article_lines = articles_info.map do |li|
          # 完全に拾えないliがある
          # titleが不完全
          # class slpが掴めない場合がある

          article_title = li.css('a').text
          article_url = CGI.parse(home_url + li.css('a').attribute('href').value)['http://www.google.co.jp/url?q'][0]
          if li.css('.slp').present?
            ary = li.css('.slp').text.strip.split(' - ')
            if ary.size == 2
              article_source = ary[0]
            else
              article_source = ary[0..-2].sum
            end
            if ary[-1] =~ /(.+)日前/
              article_date = Date.today - $1.to_i
            elsif ary[-1] =~ /(.+)時間前/
              article_date = (Time.now - 60 * 60 * $1.to_i).to_date
            elsif ary[-1] =~ /(.+)分前/
              article_date = (Time.now - 60 * $1.to_i).to_date
            elsif  ary[-1] =~ /(.+)秒前/
              article_date = (Time.now - $1.to_i).to_date
            else
              article_date = trim_to_date(ary[-1])
            end
          else
            next
          end
          [company_name, article_title, article_url, article_source, article_date]
        end
        article_lines.compact
      end

      def self.get_trend_url
        'http://www.google.co.jp/trends/hottrends/atom/hourly'
      end

      def self.add_trend_line(trend_line)
        trend_url = get_trend_url
        trend_doc = get_content(trend_url, :short)
        add_line = trend_doc.xpath('//li').map(&:text)
        trend_line += add_line
        trend_line.uniq
      end

    end
  end
end