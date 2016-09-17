# coding: utf-8
module Clawler
  module Models
    class Commodity < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        commodity_builder = self.new(:commodity, :build, true)
        commodity_builder.scrape
        commodity_builder.import
        commodity_builder.finish
      end

      def self.patrol
        commodity_patroller = self.new(:commodity, :patrol, true)
        commodity_patroller.scrape
        commodity_patroller.import
        commodity_patroller.finish
      end

      def self.import
        commodity_importer = self.new(:commodity, :import)
        commodity_importer.import
        commodity_importer.finish
      end

      def set_cut_obj(commodity_code)
        #@cut_obj = ::Commodity.where(commodity_code: commodity_code).try(:pluck, :date).try(:sort).try(:last)
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

      def each_scrape(commodity_code, page)
        commodity_lines = []
        commodities_info = Clawler::Sources::Investing.get_commodities_info(csym(:commodity, commodity_code).to_s.gsub('_', '-'), @driver, @wait)

        commodities_info.each do |commodity_info|
          commodity_line = Clawler::Sources::Investing.get_commodity_line(commodity_info, commodity_code)

          if @status == :patrol && @cut_obj.present?
            return {type: :all, lines: commodity_lines} if @cut_obj >= commodity_line[1]
          end

          commodity_lines << commodity_line
        end
        return {type: :all, lines: commodity_lines}
      end

      def line_import
        @lines.group_by{|random_line| random_line[0]}.each do |commodity_code, lines|
          ::Commodity.transaction do
            commodities = []
            last_date = ::Commodity.where(commodity_code: commodity_code).try(:pluck, :date).try(:sort).try(:last)
            commodities_info = []

            lines.sort_by{|line| line[1]}.reverse.each do |line|
              if last_date.present?
                break if last_date >= line[1] 
              end

              commodity_info = {}
              commodity_info[:date] = line[1]
              commodity_info[:closing_price] = line[2]
              commodity_info[:opening_price] = line[3]
              commodity_info[:high_price] = line[4]
              commodity_info[:low_price] = line[5]
              commodity_info[:commodity_code] = commodity_code

              commodities << ::Commodity.new(commodity_info)
            end
            commodities.each(&:save!)
          end
        end
        true
      end

      def csv_import
        commodity_codes = cvals(:commodity)

        commodity_codes.each do |commodity_code|
          ::Commodity.transaction do
            commodities = []
            last_date = ::Commodity.where(commodity_code: commodity_code).try(:pluck, :date).try(:sort).try(:last)
            commodities_info = []
            csv_text = get_csv_text(commodity_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse.uniq

            lines.each do |line|
              if last_date.present?
                break if last_date >= trim_to_date(line[1]) 
              end

              commodity_info = {}
              commodity_info[:date] = trim_to_date(line[1])
              commodity_info[:closing_price] = line[2].to_f
              commodity_info[:opening_price] = line[3].to_f
              commodity_info[:high_price] = line[4].to_f
              commodity_info[:low_price] = line[5].to_f
              commodity_info[:commodity_code] = commodity_code

              commodities << ::Commodity.new(commodity_info)
            end
            commodities.each(&:save!)
          end
        end
        true
      end

    end
  end
end
