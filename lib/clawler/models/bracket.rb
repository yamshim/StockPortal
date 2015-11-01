# coding: utf-8
module Clawler
  module Models
    class Bracket < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        bracket_builder = self.new(:bracket, :build)
        bracket_builder.scrape
        bracket_builder.import
        bracket_builder.finish
      end

      def self.patrol
        bracket_patroller = self.new(:bracket, :patrol)
        bracket_patroller.scrape
        bracket_patroller.import
        bracket_patroller.finish
      end

      def self.import
        bracket_importer = self.new(:bracket, :import)
        bracket_importer.import
        bracket_importer.finish
      end

      def set_cut_obj(bracket_code)
        @cut_obj = ::Bracket.where(bracket_code: bracket_code).try(:pluck, :date).try(:sort).try(:last)
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

      def each_scrape(bracket_code, page)
        bracket_lines = []
        brackets_info = Clawler::Sources::Minkabu.get_brackets_info(bracket_identifier(bracket_code), page)
        return {type: :break, lines: nil} if brackets_info.blank?
        
        brackets_info.each do |bracket_info|
          bracket_line = Clawler::Sources::Minkabu.get_bracket_line(bracket_info, bracket_code)

          if @status == :patrol && @cut_obj.present?
            return {type: :all, lines: bracket_lines} if @cut_obj >= bracket_line[1]
          end
          
          bracket_lines << bracket_line
        end
        return {type: :part, lines: bracket_lines}
      end

      def bracket_identifier(bracket_code)
        case csym(:bracket, bracket_code)
        when :nikkei225 then '100000018'
        when :topix then 'KSISU1000'
        when :jasdaq then 'INDEX0000'
        when :dji then '.DJI'
        when :nasdaq then '.IXIC'
        when :sse then '.SSEC'
        when :hsi then '.HSI'
        end
      end

      def line_import
        @lines.group_by{|random_line| random_line[0]}.each do |bracket_code, lines|
          ::Bracket.transaction do
            brackets = []
            last_date = ::Bracket.where(bracket_code: bracket_code).try(:pluck, :date).try(:sort).try(:last)
            brackets_info = []

            lines.sort_by{|line| line[1]}.reverse.each do |line|
              if last_date.present?
                break if last_date >= line[1] 
              end

              bracket_info = {}
              bracket_info[:date] = line[1]
              bracket_info[:opening_price] = line[2]
              bracket_info[:high_price] = line[3]
              bracket_info[:low_price] = line[4]
              bracket_info[:closing_price] = line[5]
              bracket_info[:turnover] = line[6]
              bracket_info[:bracket_code] = bracket_code

              brackets << ::Bracket.new(bracket_info)
            end
            brackets.each(&:save!)
          end
        end
        true
      end

      def csv_import
        bracket_codes = cvals(:bracket)

        bracket_codes.each do |bracket_code|
          ::Bracket.transaction do
            brackets = []
            last_date = ::Bracket.where(bracket_code: bracket_code).try(:pluck, :date).try(:sort).try(:last)
            brackets_info = []
            csv_text = get_csv_text(bracket_code)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[1])}.reverse.uniq

            lines.each do |line|
              if last_date.present?
                break if last_date >= trim_to_date(line[1]) 
              end

              bracket_info = {}
              bracket_info[:date] = trim_to_date(line[1])
              bracket_info[:opening_price] = line[2].to_f
              bracket_info[:high_price] = line[3].to_f
              bracket_info[:low_price] = line[4].to_f
              bracket_info[:closing_price] = line[5].to_f
              bracket_info[:turnover] = line[6].to_i
              bracket_info[:bracket_code] = bracket_code

              brackets << ::Bracket.new(bracket_info)
            end
            brackets.each(&:save!)
          end
        end
        true
      end

    end
  end
end
