# coding: utf-8
module Clawler
  module Models
    class Article < Clawler::Base
      extend AllUtils
      # include Clawler::Sources

      # Initializeは一番最初にスクリプトとして実行する　csv化するか、分割化するかなどはまた後で
      # sleepを入れる
      # エラーバンドリング
      # 強化
      # 重複データの保存を避ける
      # break, next

      def self.build
        article_builder = self.new(:article, :build)
        article_builder.scrape
        article_builder.import
        article_builder.finish
      end

      def self.patrol
        article_patroller = self.new(:article, :patrol)
        article_patroller.scrape
        article_patroller.import
        article_patroller.finish
      end

      def self.import
        article_importer = self.new(:article, :import)
        article_importer.import
        article_importer.finish
      end

      def self.update
        article_updater = self.new(:article, :update)
        article_updater.import
        article_updater.finish
      end

      def set_cut_obj(company_code)
        @cut_obj = nil
      end

      def scrape
        super(self.method(:each_scrape))
        # write_proxies
      end

      def import
        case @status
        when :build, :import
          super(self.method(:csv_import))
        when :patrol
          super(self.method(:line_import))
        when :update
          super(self.method(:update_import))
        end 
      end

      def each_scrape(company_name, page)
        article_lines = []
        articles_info = Clawler::Sources::Google.get_articles_info(company_name, page)
        article_lines = Clawler::Sources::Google.get_article_lines(articles_info, company_name, @lines[-1])
        return {type: :break, lines: nil} if article_lines.blank?

        if @status == :build
          if page == 100
            return {type: :all, lines: article_lines}
          else
            return {type: :part, lines: article_lines}
          end
        elsif @status == :patrol
          if page == 7
            return {type: :all, lines: article_lines}
          else
            return {type: :part, lines: article_lines}
          end
        end
      end
   
      def line_import
        companies = ::Company.all
        articles_url = ::Article.pluck(:url)

        @lines.group_by{|random_line| random_line[0]}.each do |company_name, lines|
          ::Company.transaction do
            articles_info = []
            company = companies.select{|c| c.name == company_name}[0]

            lines.each do |line|
              article_info = {}
              article_info[:title] = line[1]
              article_info[:url] = line[2]
              article_info[:source] = line[3]
              article_info[:date] = line[4]

              if articles_url.include?(article_info[:url])
                unless company.articles.pluck(:url).include?(article_info[:url])
                  company.articles << ::Article.find_by_url(article_info[:url])
                  company.save!
                end
              else
                company.articles << ::Article.new(article_info)
                company.save!
                articles_url << article_info[:url]
              end

            end
          end
        end
        true
      end

      def csv_import
        companies = ::Company.all
        articles_url = ::Article.pluck(:url)

        companies.each do |company|
          ::Company.transaction do
            articles_info = []
            csv_text = get_csv_text(company.name)
            lines = CSV.parse(csv_text).uniq

            lines.each do |line|
              article_info = {}
              article_info[:title] = line[1]
              article_info[:url] = line[2]
              article_info[:source] = line[3]
              article_info[:date] = trim_to_date(line[4])

              if articles_url.include?(article_info[:url])
                unless company.articles.pluck(:url).include?(article_info[:url])
                  company.articles << ::Article.find_by_url(article_info[:url])
                  company.save!
                end
              else
                company.articles << ::Article.new(article_info)
                company.save!
                articles_url << article_info[:url]
              end
            end
          end
        end
        true
      end

      def update_import
        companies = ::Company.all

        companies.each do |company|
          ::Company.transaction do
            article_lines = []
            articles = company.articles.where(description: nil)
            articles.each do |article|
              article_info = {}
              sleep(0.1)
              begin
                open(article.url, 'rb:utf-8') do |io|
                  html = io.read.toutf8
                  article_info[:description], article_info[:title] = ExtractContent.analyse(html)
                end
              rescue => ex
                #  OpenURI::HTTPError, RuntimeError => ex
                next # 404 Not Found のとき飛ばす あとhttp->httpsのredirect
              end
              article_info[:title] = article.title if article_info[:title].blank?
              article_info[:description] = article.description if article_info[:description].blank?

              article_line = [company.name, article_info[:title], article.url, article.source, article.date, article_info[:description]]
              article_lines << article_line
              article.update_attributes!(article_info)
            end
            update_csv(article_lines, company.name)
          end
        end
        true
      end

    end
  end
end

