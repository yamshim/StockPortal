# coding: utf-8
module Clawler
  module Models
    class ForeignExchange < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.patrol
        foreign_exchange_patroller = self.new(:foreign_exchange, :patrol)
        foreign_exchange_patroller.scrape
        foreign_exchange_patroller.import
        foreign_exchange_patroller.finish
      end

      def self.build
        foreign_exchange_builder = self.new(:foreign_exchange, :build)
        foreign_exchange_builder.build
        foreign_exchange_builder.finish
      end

      def set_latest_object(currency_code)
        @latest_object = ::ForeignExchange.where(currency_code: currency_code).try(:pluck, :date).try(:sort).try(:last)
      end

      def each_scrape(currency_code, page)
        foreign_exchange_lines = []
        foreign_exchanges_info = Clawler::Sources::Yahoo.get_foreign_exchanges_info(csym(:currency, currency_code), page)

        return {type: :break, lines: nil} if foreign_exchanges_info.blank?
        
        foreign_exchanges_info.each do |foreign_exchange_info|
          foreign_exchange_line = Clawler::Sources::Yahoo.get_foreign_exchange_line(foreign_exchange_info, currency_code)

          if @status == :patrol && @latest_object.present?
            return {type: :all, lines: foreign_exchange_lines} if @latest_object >= foreign_exchange_line[1] 
          end

          foreign_exchange_lines << foreign_exchange_line
        end
        return {type: :part, lines: foreign_exchange_lines}
      end

      def line_import
        @lines.group_by{|random_line| random_line[0]}.each do |currency_code, lines|
          ::ForeignExchange.transaction do
            foreign_exchanges = []
            last_date = ::ForeignExchange.where(currency_code: currency_code).try(:pluck, :date).try(:sort).try(:last)
            foreign_exchanges_info = []

            lines.sort_by{|line| line[1]}.reverse.each do |line|
              if last_date.present?
                break if last_date >= line[1] 
              end

              foreign_exchange_info = {}
              foreign_exchange_info[:date] = line[1]
              foreign_exchange_info[:opening_price] = line[2]
              foreign_exchange_info[:high_price] = line[3]
              foreign_exchange_info[:low_price] = line[4]
              foreign_exchange_info[:closing_price] = line[5]
              foreign_exchange_info[:currency_code] = currency_code

              foreign_exchanges << ::ForeignExchange.new(foreign_exchange_info)
            end
            foreign_exchanges.each(&:save!)
          end
        end
        true
      end

      def csv_import
        currency_codes = cvals(:currency)
        currency_codes.each do |currency_code|
          ::ForeignExchange.transaction do
            foreign_exchanges = []
            last_date = ::ForeignExchange.where(currency_code: currency_code).try(:pluck, :date).try(:sort).try(:last)
            foreign_exchanges_info = []
            csv_text = get_csv_text(currency_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse.uniq

            lines.each do |line|
              if last_date.present?
                break if last_date >= trim_to_date(line[1]) 
              end

              foreign_exchange_info = {}
              foreign_exchange_info[:date] = trim_to_date(line[1])
              foreign_exchange_info[:opening_price] = line[2].to_f
              foreign_exchange_info[:high_price] = line[3].to_f
              foreign_exchange_info[:low_price] = line[4].to_f
              foreign_exchange_info[:closing_price] = line[5].to_f
              foreign_exchange_info[:currency_code] = currency_code

              foreign_exchanges << ::ForeignExchange.new(foreign_exchange_info)
            end
            foreign_exchanges.each(&:save!)
          end
        end
        true
      end

    end
  end
end
