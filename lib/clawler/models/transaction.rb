# coding: utf-8
module Clawler
  module Models
    class Transaction < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        transaction_builder = self.new(:transaction, :build)
        transaction_builder.scrape
        transaction_builder.import
      end

      def self.patrol
        transaction_patroller = self.new(:transaction, :patrol)
        transaction_patroller.scrape
        transaction_patroller.import
      end

      def self.import
        transaction_importer = self.new(:transaction, :import)
        transaction_importer.import
      end

      def self.peel
        transaction_peeler = self.new(:transaction, :peel, true)
        transaction_peeler.scrape
        transaction_peeler.import
      end

      def set_cut_obj(company_code)
        @cut_obj = ::Company.find_by_company_code(company_code).try(:transactions).try(:map, &:date).try(:sort).try(:last)
      end

      def scrape
        if @status == :peel
          super(self.method(:chart_scrape))
          @driver.quit
        else
          super(self.method(:each_scrape))
        end
      end

      def import
        case @status
        when :build, :import
          super(self.method(:csv_import))
        when :patrol
          super(self.method(:line_import))
        when :peel
          CLAWL_LOGGER.info(cmd: "#{@model_type}##{@status}=end")
        end
      end

      def each_scrape(company_code, page)
        transaction_lines = []
        transactions_info = Clawler::Sources::Yahoo.get_transactions_info(company_code, page)

        return {type: :break, lines: nil} if transactions_info.blank?
        
        transactions_info.each do |transaction_info|
          transaction_line = Clawler::Sources::Yahoo.get_transaction_line(transaction_info, company_code)
          next if transaction_line.nil?

          if @status == :patrol && @cut_obj.present?
            return {type: :all, lines: transaction_lines} if @cut_obj >= transaction_line[1] 
          end

          transaction_lines << transaction_line
        end
        return {type: :part, lines: transaction_lines}
      end

      def line_import
        ::Company.transaction do
          companies = ::Company.includes(:transactions)

          @lines.group_by{|random_line| random_line[0]}.each do |company_code, lines|
            transactions_info = []
            company = companies.select{|c| c.company_code == company_code}[0]
            last_date = company.try(:transactions).try(:map, &:date).try(:sort).try(:last)

            lines.sort_by{|line| line[1]}.reverse.each do |line|
              if last_date.present? # 重複チェックに変えるべき?
                break if last_date >= line[1] 
              end

              transaction_info = {}
              transaction_info[:date] = line[1]
              transaction_info[:opening_price] = line[2]
              transaction_info[:high_price] = line[3]
              transaction_info[:low_price] = line[4]
              transaction_info[:closing_price] = line[5]
              transaction_info[:turnover] = line[6]
              transaction_info[:vwap] = line[7]

              transactions_info << transaction_info
            end
            company.transactions.build(transactions_info).each(&:save!)
          end
        end
        true
      rescue => ex
        error = {}
        error[:error_name] = ex.class.name
        error[:error_message] = ex.message
        error[:error_backtrace] = ex.backtrace[0]
        error[:error_file] = __FILE__
        error[:error_line] = __LINE__
        error[:error_count] = 1
        CLAWL_LOGGER.info(error)
      end

      def csv_import
        ::Company.transaction do
          companies = ::Company.includes(:transactions)

          companies.each do |company|
            last_date = company.try(:transactions).try(:map, &:date).try(:sort).try(:last)
            transactions_info = []
            csv_text = get_csv_text(company.company_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse

            lines.each do |line|
              if last_date.present? # 重複チェックに変えるべき?
                break if last_date >= trim_to_date(line[1]) 
              end

              transaction_info = {}
              transaction_info[:date] = trim_to_date(line[1])
              transaction_info[:opening_price] = line[2].to_i
              transaction_info[:high_price] = line[3].to_i
              transaction_info[:low_price] = line[4].to_i
              transaction_info[:closing_price] = line[5].to_i
              transaction_info[:turnover] = line[6].to_i
              transaction_info[:vwap] = line[7].try(:to_f)
              transactions_info << transaction_info
            end
            company.transactions.build(transactions_info).each(&:save!)
          end
        end
        true
      rescue => ex
        error = {}
        error[:error_name] = ex.class.name
        error[:error_message] = ex.message
        error[:error_backtrace] = ex.backtrace[0]
        error[:error_file] = __FILE__
        error[:error_line] = __LINE__
        error[:error_count] = 1
        CLAWL_LOGGER.info(error)
      end

      def chart_scrape(company_code, page)
        dir_name = "#{Rails.root}/public/images/#{Rails.env}/chart/#{company_code}" # 後で変更
        FileUtils.mkdir_p(dir_name) unless File.exists?(dir_name)
        file_name = dir_name + "/#{Date.today}.jpg"
        unless File.size?(file_name)
          Clawler::Sources::Sbi.get_chart(company_code, file_name, @driver, @watch)
          return {type: :break, lines: nil}
        end
      end

    end
  end
end

