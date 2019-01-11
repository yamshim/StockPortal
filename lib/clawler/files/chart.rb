# coding: utf-8
module Clawler
  module Files
    class Chart < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.patrol
        proxy_patroller = self.new(:chart, :patrol, true)
        proxy_patroller.scrape
        proxy_patroller.finish
      end

      def set_latest_object(company_code)
        @latest_object = nil
      end
      
      def chart_scrape(company_code, page)
        dir_name = "#{Rails.root}/public/images/#{Rails.env}/chart/#{company_code}" # 後で変更
        FileUtils.mkdir_p(dir_name) unless File.exists?(dir_name)

        now_time = Time.now
        now_date = now_time.to_date
        former_range = (Time.new(*[now_date.year, now_date.month, now_date.day, 15, 30, 00, '+09:00'])..Time.new(*[now_date.year, now_date.month, now_date.day, 23, 59, 59, '+09:00']))
        latter_range = (Time.new(*[now_date.year, now_date.month, now_date.day, 00, 00, 00, '+09:00'])..Time.new(*[now_date.year, now_date.month, now_date.day, 8, 49, 59, '+09:00']))
        if former_range.cover?(now_time)
          file_name = dir_name + "/#{now_date}.jpg"
        elsif latter_range.cover?(now_time)
          file_name = dir_name + "/#{now_date - 1}.jpg"
        else
          raise "ToExit:PeelTimeOver:#{now_time}"
        end

        unless File.size?(file_name)
          Clawler::Sources::Sbi.get_chart(company_code, file_name, @driver, @wait)
        end
        return {type: :break, lines: nil}
      end
    end

      def each_scrape(source, page)
        proxy_lines = case csym(:proxy_source, source)
        when :getproxy
          #Clawler::Sources::Getproxy.get_proxy_lines(page, @driver, @wait)
          []
        when :cybersyndrome
          Clawler::Sources::Cybersyndrome.get_proxy_lines(page, @driver, @wait)
        when :proxymoo
          #Clawler::Sources::Proxymoo.get_proxy_lines(page, @driver, @wait)
          []
        else
          []
        end

        return {type: :break, lines: nil} if proxy_lines[-1] == @lines[-1] || proxy_lines.blank?

        return {type: :part, lines: proxy_lines}
      end

      def line_import
        @lines += @lines + read_proxies
        @lines.uniq!

        @lines = @lines.map do |proxy|
          begin
            html = timeout(3){open('http://www.livedoor.com/', 'User-Agent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11', :read_timeout => 3, :proxy => proxy)}
            html.class == Tempfile ? proxy : nil
          rescue => ex
            nil
          end
        end.compact
        write_proxies(@lines)

        true
      end

    end
  end
end
