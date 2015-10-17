# coding: utf-8
module Clawler
  module Models
    class Company < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # 定期的に情報をアップデートするためのメソッド追加

      def self.build
        company_builder = self.new(:company, :build)
        company_builder.scrape
        company_builder.import
      end

      def self.patrol
        company_patroller = self.new(:company, :patrol)
        company_patroller.scrape
        company_patroller.import
      end

      def self.import
        company_importer = self.new(:company, :import)
        company_importer.import
      end

      def set_cut_obj(industry_code)
        @cut_obj = ::Company.where(industry_code: industry_code).map(&:company_code).sort # この処理はもっと上で行って1回きりでも
      end  

      def scrape
        super(self.method(:each_scrape))
      end

      def import
        case @status
        when :build, :import
          super(self.method(:csv_import))
        when :patrol
          super(self.method(:line_import))
        end 
      end

      def each_scrape(industry_code, page)
        company_lines = []
        company_codes = Clawler::Sources::Kabutan.get_company_codes(industry_code, page)

        return {type: :break, lines: nil} if company_codes.empty?
        if @status == :patrol
          return {type: :next, lines: nil} if (company_codes = company_codes - @cut_obj).empty?
        end

        company_codes.each do |company_code|
          company_line = Clawler::Sources::Kabutan.get_company_line(company_code, industry_code)
          next if company_line.nil?          

          company_lines << company_line
        end
        return {type: :part, lines: company_lines}
      end

      def line_import
        ::Company.transaction do
          companies = []
          existing_company_codes = ::Company.pluck(:company_code).sort

          @lines.each do |line|
            unless existing_company_codes.include?(line[1])
              company_info = {}
              company_info[:country_code] = line[0]
              company_info[:company_code] = line[1]
              company_info[:name] = line[2]
              company_info[:market_code] = line[3]
              company_info[:industry_code] = line[4]
              company_info[:trading_unit] = line[5]
              company_info[:url] = line[6]
              company_info[:established_date] = line[7]
              company_info[:listed_date] = line[8]
              company_info[:accounting_period] = line[9]
              company_info[:description] = line[10]

              companies << ::Company.new(company_info)
              existing_company_codes << company_info[:company_code]
            end
          end
          companies.each(&:save!)
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
          companies = []
          existing_company_codes = ::Company.pluck(:company_code).sort
          industry_codes = cvals(:industry)

          industry_codes.each do |industry_code|
            csv_text = get_csv_text(industry_code)
            lines = CSV.parse(csv_text)
            lines.each do |line|
              unless existing_company_codes.include?(line[1].to_i)
                company_info = {}
                company_info[:country_code] = line[0].to_i
                company_info[:company_code] = line[1].to_i
                company_info[:name] = line[2]
                company_info[:market_code] = line[3].to_i
                company_info[:industry_code] = line[4].to_i
                company_info[:trading_unit] = line[5].to_i
                company_info[:url] = line[6]
                company_info[:established_date] = trim_to_date(line[7])
                company_info[:listed_date] = trim_to_date(line[8])
                company_info[:accounting_period] = line[9].to_i
                company_info[:description] = line[10]

                companies << ::Company.new(company_info)
                existing_company_codes << company_info[:company_code]
              end
            end
          end
          companies.each(&:save!)
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

    end
  end
end

