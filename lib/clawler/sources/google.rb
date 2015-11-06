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
        case rand(3)
        when 0
          "https://www.google.co.jp/search?hl=ja&gl=jp&tbm=nws&authuser=0&q=#{URI.encode(word)}&hl=ja&gl=jp&authuser=0&tbm=nws&start=#{(page - 1) * 10}"
        when 1
          "https://www.google.co.jp/search?hl=ja&gl=jp&tbm=nws&authuser=0&q=#{URI.encode(word)}&start=#{(page - 1) * 10}"
        when 2
          "https://www.google.co.jp/search?hl=ja&gl=jp&tbm=nws&authuser=0&q=#{URI.encode(word)}&oq=#{URI.encode(word)}&start=#{(page - 1) * 10}"
        end
      end

      def self.get_articles_info(company_name, page)
        articles_url = get_articles_url(company_name, page)
        articles_doc = get_content(articles_url, :long)
        articles_info = articles_doc.css('.g')
        articles_info
      end

      def self.get_article_lines(articles_info, company_name, last_line)
        article_lines = []
        articles_info.each do |line|
          # 完全に拾えないlineがある
          # titleが不完全
          # class slpが掴めない場合がある

          article_title = line.css('h3').text
          if line.css('.slp').present?
            ary = line.css('.slp').xpath('span').map(&:text)
            article_source = ary[0]
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

          article_urls = line.css('a').map{|a| a.attribute('href').value}.uniq.reject{|url| url =~ /google/}
          lines = article_urls.map do |article_url|
            [company_name, article_title, article_url, article_source, article_date]
          end
          article_lines += lines
        end
        (article_lines.empty? || (article_lines[-1][2] == last_line[2]) || (article_lines.size < 5)) ? nil : article_lines
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