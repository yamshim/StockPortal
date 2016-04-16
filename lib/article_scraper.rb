# coding: utf-8
require 'selenium-webdriver'
require 'nokogiri'
require 'pry'

def scrape
  driver = Selenium::WebDriver.for(:phantomjs)
  wait = ::Selenium::WebDriver::Wait.new(timeout: 5)

  ["極洋", "日本水産", "マルハニチロ", "カネコ種苗", "サカタのタネ", "ホクト"].each do |word|
    ary = []
    begin
      (1..100).each do |page|
        articles_url = case rand(6)
          when 0
            "https://www.google.co.jp/search?hl=ja&gl=jp&tbm=nws&authuser=0&q=#{URI.encode(word)}&hl=ja&gl=jp&authuser=0&tbm=nws&start=#{(page - 1) * 10}"
          when 1
            "https://www.google.co.jp/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=#{URI.encode(word)}&tbm=nws&start=#{(page - 1) * 10}"
          when 2
            "https://www.google.co.jp/webhp?hl=ja#q=#{URI.encode(word)}&hl=ja&tbm=nws&start=#{(page - 1) * 10}"
          when 3
            "https://www.google.co.jp/search?hl=ja&gl=jp&tbm=nws&authuser=0&q=#{URI.encode(word)}&oq=#{URI.encode(word)}#q=#{URI.encode(word)}&hl=ja&gl=jp&authuser=0&tbm=nws&start=#{(page - 1) * 10}"
          when 4
            "https://www.google.com/search?q=#{URI.encode(word)}&oq=#{URI.encode(word)}&aqs=chrome..69i57.2059j0j7&sourceid=chrome&es_sm=91&ie=UTF-8#q=#{URI.encode(word)}&tbm=nws&start=#{(page - 1) * 10}"
          when 5
            "https://www.google.co.jp/search?client=safari&rls=en&q=#{word}&ie=UTF-8&oe=UTF-8&gfe_rd=cr&ei=YzwrVsHtMImg8wecpYq4Bg#q=#{word}&tbm=nws&start=#{(page - 1) * 10}"
          end
        driver.get(articles_url)
        sleep(10)

        page_lines = []
        es = wait.until{driver.find_elements(css: '.g')}
        es.map do |e|
          urls = wait.until{e.find_elements(tag_name: 'a')}.map{|a| a.attribute('href')}.uniq.reject{|url| url =~ /google/}
          lines = urls.map do |url|
            title = wait.until{e.find_element(tag_name: 'h3')}.text
            slp = wait.until{e.find_element(css: '.slp').find_elements(xpath: 'span')}
            source = slp[0].text
            date = slp[-1].text # trim_to_date
            [title, url, source, date]
          end
          page_lines += lines
        end
        binding.pry
        p page_lines


        # e = wait.until{driver.find_element(id: "rcnt")}
        # urls = wait.until{e.find_elements(tag_name: "a")}.map{|a| a.attribute('href')}.compact.uniq.reject{|url| url =~ /google.co.jp\/[search alert]/}.map{|url| url =~ /google.co.jp\/url/ ? CGI.parse(url)['url'][0] : url}.each{|url| p url}
        # page_url = driver.current_url
        # titles_urls = urls.map do |url|
        #   driver.get(url)
        #   title = driver.title
        #   [title, url]
        # end
        # ary += titles_urls
        # driver.get(page_url)
        break if (e = wait.until{driver.find_elements(link_text: '次へ')}[0]).nil?
      end
      p ary
    rescue => ex
      binding.pry
    end
  end
end

scrape
    
