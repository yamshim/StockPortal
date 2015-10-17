# coding: utf-8
module Clawler
  module Models
    class Trend < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        trend_builder = self.new(:trend, :build)
        trend_builder.scrape
        trend_builder.import
      end

      def self.patrol
        trend_patroller = self.new(:trend, :patrol)
        trend_patroller.scrape
        trend_patroller.import
      end

      def self.import
        trend_importer = self.new(:trend, :import)
        trend_importer.import
      end

      def set_cut_obj(source)
        @cut_obj = ::Trend.pluck(:date).try(:sort).try(:last)
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

      def each_scrape(source, page)
        trend_lines = []
        urls = Clawler::Sources::Nikkei.get_urls(page)

        return {type: :break, lines: nil} if urls.blank?

        urls.each do |url|
          date, texts = Clawler::Sources::Nikkei.get_info(url)

          next if date >= Date.today # 前日までの記事を対象にする 例えば25日の25時にクロールすることを前提にして25日までの記事をチェックするように
          if @status == :patrol && @cut_obj.present?
            return {type: :all, lines: trend_lines} if @cut_obj >= date
          end
          words = Clawler::Sources::Yahoo.get_words(texts)
          trend_lines << [date, words]
        end
        return {type: :part, lines: trend_lines}
      end

      def post_process(trend_lines)
        processed_lines = []
        trend_lines.group_by{|trend_line| trend_line[0]}.each do |date, lines|
          processed_line = [date]
          words_scores = []
          lines.each{|line| words_scores += line[1]}
          processed_line += Clawler::Sources::Yahoo.process_line(words_scores)
          processed_line = Clawler::Sources::Google.add_trend_line(processed_line) if (date + 1).today?

          processed_lines << processed_line
        end
        @lines = processed_lines.clone # objsが一つだからいいが、複数になるとpatrolのとき成り立たなくなる
        processed_lines
      end

      def line_import
        ::Trend.transaction do
          existing_tags = ::Tag.where(tag_type: c(:tag_type, :trend)).pluck(:name)
          last_date = ::Trend.pluck(:date).try(:sort).try(:last)

          @lines.sort_by{|line| line[0]}.reverse.each do |line|
            if last_date.present?
              break if last_date >= line[0]
            end

            trend = ::Trend.new({date: line[0]})
            line[1..-1].each do |li|
              if existing_tags.include?(li)
                trend.tags << ::Tag.find_by_name(li)
                trend.save!
              else
                trend.tags << ::Tag.new({name: li, tag_type: c(:tag_type, :trend)})
                trend.save!
                existing_tags << li
              end
            end
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
        ::Trend.transaction do
          existing_tags = ::Tag.where(tag_type: c(:tag_type, :trend)).try(:map, &:name)
          last_date = ::Trend.pluck(:date).try(:sort).try(:last)

          cvals(:trend_source).each do |source|
            csv_text = get_csv_text(source)
            lines = CSV.parse(csv_text).sort_by{|line| trim_to_date(line[0])}.reverse

            lines.each do |line|
              if last_date.present?
                break if last_date >= trim_to_date(line[0])
              end

              trend = ::Trend.new({date: trim_to_date(line[0])})
              line[1..-1].each do|li|
                if existing_tags.include?(li)
                  trend.tags << ::Tag.find_by_name(li)
                  trend.save!
                else
                  trend.tags << ::Tag.new({name: li, tag_type: c(:tag_type, :trend)})
                  trend.save!
                  existing_tags << li
                end
              end
            end
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

    end
  end
end
