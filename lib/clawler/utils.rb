module Clawler
  module Utils
    require 'open-uri'
    require 'nokogiri'
    require 'cgi'
    require 'zlib'
    require 'rexml/document'

    def get_content(url, interval)
      wait(interval)
      html = open(url, 'User-Agent' => 'Ruby/#{RUBY_VERSION}')
      charset = html.charset
      Nokogiri::HTML.parse(html, nil, charset)
    end

    def wait(interval)
      case interval
      when :short
        sleep(0.0001)
      when :middle
        sleep(0.1)
      when :long
        sleep(15)
      end
    end

    def scrape_start_date # これあんまよくないかも
      Date.new(1980, 1, 1)
    end

    def scrape_end_date # これあんまよくないかも
      Date.today
    end

  end
end