module Clawler
  module Utils
    require 'open-uri'
    require 'nokogiri'
    require 'cgi'
    require 'zlib'
    require 'rexml/document'

    include AllUtils

    def get_content(url, interval)
      error_info = []
      wait_interval(interval)
      begin
        # $proxyの初値は必ずnil
        html = timeout(10){open(url, 'User-Agent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11', :read_timeout => 10, :proxy => $proxy)}
        charset = html.charset
        Nokogiri::HTML.parse(html, nil, charset) 
      rescue => ex
        # サイトにアクセスするというアクションに対する例外を補足 サーバがダウンしている、urlが間違っている、ipアドレスがbanされている、など
        error_info << add_error_info(:get_content, url, ex)
        CLAWL_LOGGER.info({action: 'ERROR', source: self, error_info: error_info.last})
        if error_info.count >= 100 # エラーの理由によって条件を変えるべきかも
          # ここに達したら処理終了
          CLAWL_LOGGER.info({action: 'FAILURE', source: self, error_info: error_info.last})
          send_logger_mail({action: 'FAILURE', source: self, method: :get_content}, {error_info: error_info})
          exit
        end
        # change_proxy
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

    def add_error_info(method, object, ex)
      error = {}
      error[:method] = method
      error[:object] = object
      error[:class_name] = ex.class.name
      error[:message] = ex.message
      error[:backtrace] = ex.backtrace[0]
      error[:proxy] = $proxy
      error
    end

    def set_proxies
      $proxy = nil
      $proxies = read_proxies
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

    def set_driver
      capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11')
      driver = ::Selenium::WebDriver.for(:phantomjs, :desired_capabilities => capabilities)
      wait = ::Selenium::WebDriver::Wait.new(timeout: 10)
      [driver, wait]
    end

  end
end