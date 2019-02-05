# coding: utf-8

module Clawler
  class Base
    include Clawler::Utils

    def initialize(clawler_type, status, driver=nil)
      @clawler_type = clawler_type
      @status = status
      @error_info = []
      @objects = []
      @sample_lines = [] # 逐次保存するならメール確認用に必要
      @lines = [] # 全てのobjectのlinesを入れる可能性がある
      set_proxies # articleのときだけにするかどうか
      if driver
        @driver, @wait = set_driver
      end
    end

    def get_iterated_objects
      # loop対象のオブジェクトをセット
      case @clawler_type
      when :company
        cvals(:industry).sort
      when :transaction, :credit_deal, :article
        Company.pluck(:company_code).sort
      when :foreign_exchange
        cvals(:currency).sort
      when :bracket
        cvals(:bracket).sort
      when :trend
        cvals(:trend_source).sort
      when :commodity
        cvals(:commodity).sort
      when :proxy
        cvals(:proxy_source).sort
      end
    end

    def scrape
      log_output(:scrape, :start) # startログ
      @objects = get_iterated_objects
      object_count = 0

      loop do
        begin
          @objects[object_count..-1].each do |object|
            object_lines = [] # 各objectのlinesのみ入れる
            set_latest_object(object) if [:patrol, :update].include?(@status) # 検討

            (1..1000000).each do |page|
              log_output(:scrape, :progress, object, page) # progressログ
              # result = each_scrape.call(object, page)
              result = self.each_scrape(object, page)
              case result[:type]
              when :break # resultが空かつ終了 処理的には:allと統合してもいい
                object_lines = get_uniq_lines(object_lines)
                break
              when :next # resultを追加せずスキップ
                next
              when :part # resultを追加して続行
                object_lines += result[:lines]
              when :all # resultを追加して終了
                object_lines += result[:lines]
                object_lines = get_uniq_lines(object_lines)
                break
              end
            end

            @lines += object_lines
            object_lines = self.post_process(object_lines) if @clawler_type == :trend # 検討

            if @lines.count >= 1 # 今のところ逐次保存
              self.line_import # ここのselfはClawler::Models::Transactionなどのインスタンス
              log_output(:scrape, :import, object) # importログ, objectまでのimportを完了
              @sample_lines += @lines if @sample_lines.count <= 5 # 逐次保存するならメール確認用に必要
              @lines = []
            end

            object_count += 1 # 上記の処理が全て成功していたらカウント
          end
        rescue => ex
          # サイトへのアクセス以外の例外を補足
          @error_info << add_error_info(:scrape, @objects[object_count], ex)
          log_output(:scrape, :error, @objects[object_count]) # errorログ
          if @error_info.count >= 100
            # ここに達したら処理終了
            log_output(:scrape, :failure, @objects[object_count]) # exitログ
            send_logger_mail({action: 'FAILURE', clawler_type: @clawler_type, status: @status, method: :scrape, proxy: $proxy}, {error_info: @error_info}) # exitメール
            @driver.quit unless @driver.nil?
            exit
          end
          object_count += 1 # エラーを起こしたobjectをスキップして処理を続行
          retry
        end
        break if object_count == @objects.count
      end

      @driver.quit unless @driver.nil?
      log_output(:scrape, :end) # endログ
    end

    def import # 逐次保存だとpatrolで保存処理が発生しない
      log_output(:import, :start)
      case @status
      when :build
        self.csv_import
      when :patrol
        self.line_import
      when :update
        self.update_import
      end
      log_output(:import, :end)
    rescue => ex
      @error_info << add_error_info(:import, @objects.last, ex)
      log_output(:import, :failure, @objects.last)
      send_logger_mail({action: 'FAILURE', clawler_type: @clawler_type, status: @status, method: :import, proxy: $proxy}, {error_info: @error_info})
      exit
    end

    def export
      @objects = get_iterated_objects
      #@objects[0..0].each do |object|
      [2928, 3966].each do |object|
        self.each_export(object)
      end
    end

    def finish
      if @error_info.present? && (@error_info.count == @objects.count) # scrape通らない場合、@objects = []
        header = {action: 'FAILURE', clawler_type: @clawler_type, status: @status, method: :finish, proxy: $proxy}
        content = {error_info: @error_info}
        action = 'FAILURE'
      elsif @error_info.present?
        header = {action: 'SUCCESS+ERROR', clawler_type: @clawler_type, status: @status, method: :finish, proxy: $proxy}
        content = {error_info: @error_info}
        action = 'SUCCESS+ERROR'
      else
        header = {action: 'SUCCESS', clawler_type: @clawler_type, status: @status, method: :finish, proxy: $proxy}
        content = {}
        action = 'SUCCESS'
      end
      case @clawler_type
      when :chart
        dir_name = "#{Rails.root}/public/images/#{Rails.env}/chart/9501/" # サンプル送信
        content[:attachment] = dir_name + Dir::entries(dir_name).sort[-1]
      else
        content[:lines] = @sample_lines
      end
      CLAWL_LOGGER.info({action: action, clawler_type: @clawler_type, status: @status, method: :finish, proxy: $proxy, error_info: @error_info.last})
      send_logger_mail(header, content)
    end

    def build_csv(lines, object)
      dir_name = "#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@clawler_type}"
      FileUtils.mkdir_p(dir_name) unless File.exists?(dir_name)
      file_name = dir_name + "/#{@clawler_type}_lines_#{object}.csv"
      CSV.open(file_name, 'wb') do |writer|
        lines.each do |line|
          writer << line
        end
      end
    end

    def add_csv(lines, object)
      csv_text = get_csv_text(object)
      lines = case @clawler_type
      when :trend
        uniq_objects = CSV.parse(csv_text).map{|line| trim_to_date(line[0])}
        lines.reject{|line| uniq_objects.include?(line[0])}
      when :company
        uniq_objects = CSV.parse(csv_text).map{|line| line[1].to_i}
        lines.reject{|line| uniq_objects.include?(line[1])}
      when :transaction, :credit_deal, :foreign_exchange, :bracket, :commodity
        uniq_objects = CSV.parse(csv_text).map{|line| trim_to_date(line[1])}
        lines.reject{|line| uniq_objects.include?(line[1])}
      when :article
        uniq_objects = CSV.parse(csv_text).map{|line| line[2]}
        lines.reject{|line| uniq_objects.include?(line[2])}
      end

      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@clawler_type}/#{@clawler_type}_lines_#{object}.csv", 'ab+') do |writer|
        lines.each do |line|
          writer << line
        end
      end

      if @clawler_type == :article
        CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@clawler_type}/tmp.csv", 'ab+') do |writer|
          lines.each do |line|
            writer << line
          end
        end
      end
    end

    def update_csv(lines, object)
      csv_text = get_csv_text(object)
      csv_lines = CSV.parse(csv_text).uniq
      lines = case @clawler_type
      when :company
        update_company_codes = lines.map{|line| line[1]}
        csv_lines = csv_lines.reject{|csv_line| update_company_codes.include?(csv_line[1].to_i)}
        (csv_lines + lines).sort_by{|line| line[1].to_i}
      when :article
        update_urls = lines.map{|line| line[2]}
        csv_lines = csv_lines.reject{|csv_line| update_urls.include?(csv_line[2])}
        (csv_lines + lines)
      end
        
      CSV.open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@clawler_type}/#{@clawler_type}_lines_#{object}.csv", 'wb') do |writer|
        lines.each do |line|
          writer << line
        end
      end
    end

    def get_csv_text(object)
      open("#{Rails.root}/db/seeds/csv/#{Rails.env}/#{@clawler_type}/#{@clawler_type}_lines_#{object}.csv", &:read).toutf8.strip
    rescue => ex
      '' # ファイルが存在しない時空文字を返す
    end

    def get_uniq_lines(lines)
      lines = case @clawler_type
      when :trend, :proxy
        lines
      when :company, :transaction, :credit_deal, :foreign_exchange, :bracket, :commodity
        lines.uniq{|line| line[1]} # companyはcompany_code, それ以外はdateでuniq
      when :article
        lines.uniq{|line| line[2]} # articleはurlでuniq
      end
    end

    def log_output(method, action, object=nil, page=nil)
      case action
      when :start, :end, :progress
        CLAWL_LOGGER.info({action: action.to_s.upcase, clawler_type: @clawler_type, status: @status, method: method, object: object, page: page, proxy: $proxy})
      when :error, :exit
        CLAWL_LOGGER.info({action: action.to_s.upcase, clawler_type: @clawler_type, status: @status, method: method, object: object, page: page, proxy: $proxy, error_info: @error_info.last})
      end
    end

  end
end