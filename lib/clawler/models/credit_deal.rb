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

      def self.patrol
        credit_deal_patroller = self.new(:credit_deal, :patrol)
        credit_deal_patroller.scrape
        credit_deal_patroller.import
        credit_deal_patroller.finish
      end

      def self.build
        credit_deal_builder = self.new(:credit_deal, :build)
        credit_deal_builder.build
        credit_deal_builder.finish
      end

      def set_latest_object(company_code)
        @latest_object = ::Company.find_by_company_code(company_code).try(:credit_deals).try(:pluck, :date).try(:sort).try(:last)
      end

      def each_scrape(company_code, page)
        credit_deal_lines = []
        credit_deals_info = Clawler::Sources::Yahoo.get_credit_deals_info(company_code, page)

        return {type: :break, lines: nil} if credit_deals_info.blank?
        
        credit_deals_info.each do |credit_deal_info|
          credit_deal_line = Clawler::Sources::Yahoo.get_credit_deal_line(credit_deal_info, company_code)

          if @status == :patrol && @latest_object.present?
            return {type: :all, lines: credit_deal_lines} if @latest_object >= credit_deal_line[1] 
          end

          credit_deal_lines << credit_deal_line
        end
        return {type: :part, lines: credit_deal_lines}
      end

      def line_import
        companies = ::Company.all

        @lines.group_by{|random_line| random_line[0]}.each do |company_code, lines|
          ::Company.transaction do
            credit_deals_info = []
            company = companies.select{|c| c.company_code == company_code}[0]
            last_date = company.try(:credit_deals).try(:pluck, :date).try(:sort).try(:last)

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
      end

      def csv_import
        companies = ::Company.all

        companies.each do |company|
          ::Company.transaction do
            last_date = company.try(:credit_deals).try(:pluck, :date).try(:sort).try(:last)
            credit_deals_info = []
            csv_text = get_csv_text(company.company_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse.uniq

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
      end

    end
  end
end
