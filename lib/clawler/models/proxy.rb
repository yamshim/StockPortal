# coding: utf-8
module Clawler
  module Models
    class Proxy < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.patrol
        proxy_patroller = self.new(:proxy, :patrol, true)
        proxy_patroller.scrape
        proxy_patroller.import
        proxy_patroller.finish
      end

      def set_cut_obj(company_code)
        @cut_obj = nil
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
        proxy_lines = case csym(:proxy_source, source)
        when :getproxy
          Clawler::Sources::Getproxy.get_proxy_lines(page, @driver, @wait)
        when :cybersyndrome
          Clawler::Sources::Cybersyndrome.get_proxy_lines(page, @driver, @wait)
        when :proxymoo
          Clawler::Sources::Proxymoo.get_proxy_lines(page, @driver, @wait)
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
            html = timeout(10){open(Clawler::Sources::Kabutan.home_url, 'User-Agent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11', :read_timeout => 10, :proxy => proxy)}
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
