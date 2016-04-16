module Clawler
  module Utils
    require 'open-uri'
    require 'nokogiri'
    require 'cgi'
    require 'zlib'
    require 'rexml/document'

    def get_content(url, interval)
      error = {}
      error[:error_count] = 0
      wait_interval(interval)
      begin
        # $proxyの初値は必ずnil
        html = timeout(10){open(url, 'User-Agent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11', :read_timeout => 10, :proxy => $proxy)}
        charset = html.charset
        Nokogiri::HTML.parse(html, nil, charset) 
      rescue => ex
        error[:error_count] += 1
        if error[:error_count] % $proxy_size == 0
          error[:action] = "LOAD=#{$proxy}##{url}=ERROR"
          error[:error_name] = ex.class.name
          error[:error_message] = ex.message
          error[:error_backtrace] = ex.backtrace[0]
          error[:proxy] = $proxy
          error[:url] = url
          CLAWL_LOGGER.info(error)
          send_logger_mail(error)
          sleep(600)
        end
        change_proxy
        retry
      end
    end

    def wait_interval(interval)
      case interval
      when :short
        sleep(0.0005)
      when :middle
        sleep(0.1)
      when :long
        sleep(5)
      end
    end

    def scrape_start_date # これあんまよくないかも
      Date.new(1980, 1, 1)
    end

    def scrape_end_date # これあんまよくないかも
      Date.today
    end

    def set_proxies
      $proxies = read_proxies
      $proxy_size = $proxies.size + 1 # nilも含めるため+1
    end

    def change_proxy
      $proxies << $proxy
      $proxies.uniq!
      $proxy = $proxies.shift
    end

    def read_proxies
      csv_text = open("#{Rails.root}/db/seeds/csv/#{Rails.env}/proxies.csv", &:read).toutf8.strip
      proxies = CSV.parse(csv_text).flatten
      proxies
    end

    def write_proxies(proxies)
      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/proxies.csv", 'wb') do |writer|
        writer << proxies
      end
    end

  end
end