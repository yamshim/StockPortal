# coding: utf-8
module Clawler
  module Models
    class CreditDeal < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        credit_deal_builder = self.new(:credit_deal, :build)
        credit_deal_builder.scrape
        credit_deal_builder.import
      end

      def self.patrol
        credit_deal_patroller = self.new(:credit_deal, :patrol)
        credit_deal_patroller.scrape
        credit_deal_patroller.import
      end

      def self.import
        credit_deal_importer = self.new(:credit_deal, :import)
        credit_deal_importer.import
      end

      def set_cut_obj(company_code)
        @cut_obj = ::Company.find_by_company_code(company_code).try(:credit_deals).try(:map, &:date).try(:sort).try(:last)
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

      def each_scrape(company_code, page)
        credit_deal_lines = []
        credit_deals_info = Clawler::Sources::Yahoo.get_credit_deals_info(company_code, page)

        return {type: :break, lines: nil} if credit_deals_info.blank?
        
        credit_deals_info.each do |credit_deal_info|
          credit_deal_line = Clawler::Sources::Yahoo.get_credit_deal_line(credit_deal_info, company_code)

          if @status == :patrol && @cut_obj.present?
            return {type: :all, lines: credit_deal_lines} if @cut_obj >= credit_deal_line[1] 
          end

          credit_deal_lines << credit_deal_line
        end
        return {type: :part, lines: credit_deal_lines}
      end

      def line_import
        ::Company.transaction do
          companies = ::Company.all

          @lines.group_by{|random_line| random_line[0]}.each do |company_code, lines|
            credit_deals_info = []
            company = companies.select{|c| c.company_code == company_code}[0]
            last_date = company.try(:credit_deals).try(:map, &:date).try(:sort).try(:last)

            lines.sort_by{|line| line[1]}.reverse.each do |line|
              if last_date.present?
                break if last_date >= line[1]
              end

              credit_deal_info = {}
              credit_deal_info[:date] = line[1]
              credit_deal_info[:selling_balance] = line[2]
              credit_deal_info[:debt_balance] = line[3]
              credit_deal_info[:margin_ratio] = line[6]
              credit_deals_info << credit_deal_info
            end
            company.credit_deals.build(credit_deals_info).each(&:save!)
          end
        end
        true
      rescue => ex
        p ex
      end

      def csv_import
        ::Company.transaction do
          companies = ::Company.all

          companies.each do |company|
            last_date = company.try(:credit_deals).try(:map, &:date).try(:sort).try(:last)
            credit_deals_info = []
            csv_text = get_csv_text(company.company_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse

            lines.each do |line|
              if last_date.present?
                break if last_date >= trim_to_date(line[1]) 
              end

              credit_deal_info = {}
              credit_deal_info[:date] = trim_to_date(line[1])
              credit_deal_info[:selling_balance] = line[2].to_i
              credit_deal_info[:debt_balance] = line[3].to_i
              credit_deal_info[:margin_ratio] = line[6].to_f
              credit_deals_info << credit_deal_info
            end
            company.credit_deals.build(credit_deals_info).each(&:save!)
          end
        end
        true
      rescue => ex
        p ex
      end


    end
  end
end
