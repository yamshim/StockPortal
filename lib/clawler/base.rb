# coding: utf-8

module Clawler
  class Base
    include AllUtils
    include Clawler::Utils

    def initialize(model_type, status, driver=nil)
      @model_type = model_type
      @status = status
      if driver
        @driver = ::Selenium::WebDriver.for(:phantomjs)
        @watch = ::Selenium::WebDriver::Wait.new(timeout: 5)
      end
      CLAWL_LOGGER.info(cmd: "#{@model_type}##{@status}=start")
    end

    def scrape(each_scrape)
      objs = iterate_objs
      set = 0
      error = {}
      @lines = [] # 全てのlineを格納

      loop do #ループの回数制限つけるべき
        begin
          objs[set..-1].each do |obj|
            obj_lines = []
            set_cut_obj(obj) if @status == :patrol
            CLAWL_LOGGER.info({obj: obj})
            (1..1000000).each do |page|
              CLAWL_LOGGER.info({page: page})
              result = each_scrape.call(obj, page)
              case result[:type]
              when :break
                break
              when :next
                next
              when :part
                obj_lines = obj_lines + result[:lines]
                @lines = (@lines || []) + result[:lines]
              when :all
                obj_lines = obj_lines + result[:lines]
                @lines = (@lines || []) + result[:lines]
                break
              end
            end
            obj_lines = self.post_process(obj_lines) if @model_type == :trend
            @lines = nil if @status == :build
            build_csv(obj_lines, obj) if @status == :build
            update_csv(obj_lines, obj) if @status == :patrol
            set += 1 # 上記の処理が全て成功していたらカウント
          end
        rescue => ex
          if error[:error_name] == ex.class.name && error[:error_message] == ex.message && error[:error_backtrace] == ex.backtrace[0]
            error[:error_count] += 1
            if error[:error_count] >= 10
              CLAWL_LOGGER.info(error)
              CLAWL_LOGGER.info(cmd: "#{@model_type}##{@status}=exit")
              # メール送信
              @driver.quit unless @driver.nil?
              exit
            end
          else
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
      each_import.call
      CLAWL_LOGGER.info(cmd: "#{@model_type}##{@status}=end")
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

    def update_csv(lines, obj)
      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@model_type}/#{@model_type}_lines_#{obj}.csv", 'ab+') do |writer|
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

  end
end