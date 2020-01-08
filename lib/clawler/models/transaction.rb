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

      def self.patrol # 巡回してデータを取得、新しくデータベースに追加
        transaction_patroller = self.new(:transaction, :patrol)
        transaction_patroller.scrape
        transaction_patroller.import
        transaction_patroller.finish
      end

      def self.fetch # データベースのデータをCSVに保存（追加かリライトか）
        transaction_fetcher = self.new(:transaction, :fetch)
        transaction_fetcher.export
        transaction_fetcher.finish
      end

      def self.build # CSVのデータをデータベースに新しく保存
        transaction_builder = self.new(:transaction, :build)
        transaction_builder.import
        transaction_builder.finish
      end

      def set_latest_object(company_code)
        @latest_object = ::Company.find_by_company_code(company_code).try(:transactions).try(:pluck, :date).try(:sort).try(:last)
      end

      def each_scrape(company_code, page)
        transaction_lines = []
        transactions_info = Clawler::Sources::Yahoo.get_transactions_info(company_code, page)

        return {type: :break, lines: nil} if transactions_info.blank?
        
        transactions_info.each_with_index do |transaction_info, index|
          transaction_line = Clawler::Sources::Yahoo.get_transaction_line(transaction_info, company_code, page, index)
          next if transaction_line.nil?

          if @status == :patrol && @latest_object.present?
            return {type: :all, lines: transaction_lines} if @latest_object >= transaction_line[1] 
          end

          transaction_lines << transaction_line
        end
        return {type: :part, lines: transaction_lines}
      end

      def line_import
        companies = ::Company.all

        @lines.group_by{|random_line| random_line[0]}.each do |company_code, lines|
          ::Company.transaction do
            transactions_info = []
            company = companies.select{|c| c.company_code == company_code}[0]
            last_date = company.try(:transactions).try(:pluck, :date).try(:sort).try(:last)

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
              transaction_info[:tick_count] = line[8]
              transaction_info[:trading_value] = line[9]

              transactions_info << transaction_info
            end
            company.transactions.build(transactions_info).each(&:save!)
          end
        end
      end

      def csv_import
        companies = ::Company.all

        companies.each do |company|
          ::Company.transaction do
            last_date = company.try(:transactions).try(:pluck, :date).try(:sort).try(:last)
            transactions_info = []
            csv_text = get_csv_text(company.company_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse.uniq

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
              transaction_info[:tick_count] = line[8].try(:to_i)
              transaction_info[:trading_value] = line[9].try(:to_i)
              transactions_info << transaction_info
            end
            company.transactions.build(transactions_info).each(&:save!)
          end
        end
      end

      def each_export(company_code)
        lines = []
        transactions = ::Company.find_by_company_code(company_code).transactions.order(:date)
        transactions.each do |transaction|
          transaction_line = []
          transaction_line << transaction.company.company_code
          transaction_line << transaction.date
          transaction_line << transaction.opening_price
          transaction_line << transaction.high_price
          transaction_line << transaction.low_price
          transaction_line << transaction.closing_price
          transaction_line << transaction.turnover
          transaction_line << transaction.vwap
          transaction_line << transaction.tick_count
          transaction_line << transaction.trading_value
          lines << transaction_line
        end
        dir = "#{Rails.root}/tmp/export_file"
        FileUtils.mkdir_p(dir) unless File.exists?(dir)
        path = dir + "/#{@clawler_type}_lines_#{company_code}.csv"
        CSV.open(path, 'wb') do |writer|
          lines.each do |line|
            writer << line
          end
        end
        header = {action: 'SUCCESS', clawler_type: @clawler_type, status: @status, method: :export, proxy: $proxy}
        content = {attachment: path}
        send_logger_mail(header, content)
        FileUtils.rm(path)
      end

    end
  end
end

