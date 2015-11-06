# coding: utf-8

module Clawler
  class Base
    include AllUtils
    include Clawler::Utils

    def initialize(model_type, status, driver=nil)
      @model_type = model_type
      @status = status
      set_proxies
      if driver
        set_selenium
      end
    end

    def scrape(each_scrape)
      objs = iterate_objs
      set = 0
      error = {}
      @lines = []

      CLAWL_LOGGER.info(action: "SCRAPE=#{@model_type}##{@status}=START")
      loop do
        begin
          objs[set..-1].each do |obj|
            obj_lines = []
            set_cut_obj(obj) if [:patrol, :update].include?(@status)
            (1..1000000).each do |page|
              CLAWL_LOGGER.info({action: "SCRAPE=#{@model_type}##{@status}=PROGRESS", obj: obj, page: page, proxy: $proxy})
              result = each_scrape.call(obj, page)
              case result[:type]
              when :break
                obj_lines = uniq_lines(obj_lines)
                break
              when :next
                next
              when :part
                obj_lines = obj_lines + result[:lines]
                @lines = (@lines || []) + result[:lines]
              when :all
                obj_lines = obj_lines + result[:lines]
                @lines = (@lines || []) + result[:lines]
                obj_lines = uniq_lines(obj_lines)
                break
              end
            end
            obj_lines = self.post_process(obj_lines) if @model_type == :trend
            @lines = [] if @status == :build

            build_csv(obj_lines, obj) if @status == :build
            add_csv(obj_lines, obj) if @status == :patrol
            update_csv(obj_lines, obj) if @status == :update
            set += 1 # 上記の処理が全て成功していたらカウント
          end
        rescue => ex
          if error[:error_name] == ex.class.name && error[:error_message] == ex.message && error[:error_backtrace] == ex.backtrace[0]
            error[:error_count] += 1
            if error[:error_count] >= 10
              @driver.quit unless @driver.nil?
              CLAWL_LOGGER.info(error)
              send_logger_mail(error)
              exit
            end
          else
            error[:action] = "SCRAPE=#{@model_type}##{@status}=EXIT"
            error[:error_name] = ex.class.name
            error[:error_message] = ex.message
            error[:error_backtrace] = ex.backtrace[0]
            error[:error_file] = __FILE__
            error[:error_line] = __LINE__
            error[:error_count] = 1
          end
        end
        break if set == objs.size
      end
      CLAWL_LOGGER.info(action: "SCRAPE=#{@model_type}##{@status}=END")

      @lines
    end

    def iterate_objs
      case @model_type
      when :company
        cvals(:industry)
      when :transaction, :credit_deal
        Company.pluck(:company_code)
      when :foreign_exchange
        cvals(:currency)
      when :article
        Company.pluck(:name)
      when :bracket
        cvals(:bracket)
      when :trend
        cvals(:trend_source)
      when :commodity
        cvals(:commodity)
      end
    end

    def import(each_import)
      CLAWL_LOGGER.info(action: "IMPORT=#{@model_type}##{@status}=START")
      each_import.call
      CLAWL_LOGGER.info(action: "IMPORT=#{@model_type}##{@status}=END")
    rescue => ex
      error = {}
      error[:action] = "IMPORT=#{@model_type}##{@status}=EXIT"
      error[:error_name] = ex.class.name
      error[:error_message] = ex.message
      error[:error_backtrace] = ex.backtrace[0]
      error[:error_file] = __FILE__
      error[:error_line] = __LINE__
      error[:error_count] = 1
      CLAWL_LOGGER.info(error)
      send_logger_mail(error) # ここでexceptionが起こったら？
      exit
    end

    def finish
      hash = {}
      hash[:action] = "FINISH##{@model_type}=#{@status}=SUCCESS"
      case @status
      when :build, :import, :update
      when :patrol
        hash[:lines] = @lines[0..1]
      when :peel
        hash[:attachment] = "#{Rails.root}/public/images/#{Rails.env}/chart/9501/#{Date.today}.jpg"
      end
      CLAWL_LOGGER.info(hash)
      send_logger_mail(hash)
      true
    end

    def build_csv(lines, obj)
      dir_name = "#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@model_type}"
      FileUtils.mkdir_p(dir_name) unless File.exists?(dir_name)
      file_name = dir_name + "/#{@model_type}_lines_#{obj}.csv"
      CSV.open(file_name, 'wb') do |writer|
        lines.each do |line|
          writer << line
        end
      end
    end

    def add_csv(lines, obj)
      csv_text = get_csv_text(obj)
      lines = case @model_type
      when :trend
        uniq_objs = CSV.parse(csv_text).map{|line| trim_to_date(line[0])}
        lines.reject{|line| uniq_objs.include?(line[0])}
      when :company
        uniq_objs = CSV.parse(csv_text).map{|line| line[1].to_i}
        lines.reject{|line| uniq_objs.include?(line[1])}
      when :transaction, :credit_deal, :foreign_exchange, :bracket, :commodity
        uniq_objs = CSV.parse(csv_text).map{|line| trim_to_date(line[1])}
        lines.reject{|line| uniq_objs.include?(line[1])}
      when :article
        uniq_objs = CSV.parse(csv_text).map{|line| line[2]}
        lines.reject{|line| uniq_objs.include?(line[2])}
      end

      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@model_type}/#{@model_type}_lines_#{obj}.csv", 'ab+') do |writer|
        lines.each do |line|
          writer << line
        end
      end
    end

    def update_csv(lines, obj)
      csv_text = get_csv_text(obj)
      csv_lines = CSV.parse(csv_text).uniq
      lines = case @model_type
      when :company
        update_company_codes = lines.map{|line| line[1]}
        csv_lines = csv_lines.reject{|csv_line| update_company_codes.include?(csv_line[1].to_i)}
        (csv_lines + lines).sort_by{|line| line[1].to_i}
      when :article
        update_urls = lines.map{|line| line[2]}
        csv_lines = csv_lines.reject{|csv_line| update_urls.include?(csv_line[2])}
        (csv_lines + lines)
      end
        
      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@model_type}/#{@model_type}_lines_#{obj}.csv", 'wb') do |writer|
        lines.each do |line|
          writer << line
        end
      end
    end

    def get_csv_text(obj)
      open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@model_type}/#{@model_type}_lines_#{obj}.csv", &:read).toutf8.strip
    rescue => ex
      '' # ファイルが存在しない時空文字を返す
    end

    def uniq_lines(lines)
      lines = case @model_type
      when :trend
        lines
      when :company, :transaction, :credit_deal, :foreign_exchange, :bracket, :commodity
        lines.uniq{|line| line[1]}
      when :article
        lines.uniq{|line| line[2]}
      end
    end

    def set_selenium
      capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11')
      @driver = ::Selenium::WebDriver.for(:phantomjs, :desired_capabilities => capabilities)
      @watch = ::Selenium::WebDriver::Wait.new(timeout: 5)
    end

  end
end