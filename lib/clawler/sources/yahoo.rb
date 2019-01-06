# coding: utf-8

module Clawler
  module Sources
    module Yahoo
      extend AllUtils
      extend Clawler::Utils
      EXTRACT_API_BASE_URL = 'https://jlp.yahooapis.jp/KeyphraseService/V1/extract'

      def self.home_url
        'https://www.yahoo.co.jp'
      end

      def self.finance_url
        'https://finance.yahoo.co.jp'
      end

      # ---company---

      def self.get_company_url(company_code)
        "https://profile.yahoo.co.jp/fundamental/?s=#{company_code}"
      end

      def self.get_company_info(company_code)
        company_info = []
        company_url = get_company_url(company_code)
        company_doc = get_content(company_url, :middle)
        company_info << company_doc.xpath('//table')[3].css('tr')[9].css('td')[1].text.strip # establishd_date
        company_info << company_doc.xpath('//table')[3].css('tr')[11].css('td')[1].text.strip # listed_date
        company_info << company_doc.xpath('//table')[3].css('tr')[12].css('td')[1].text.strip # accounting_period
        company_info << company_doc.xpath('//table')[3].css('tr')[1].css('td')[1].text.strip # description
        company_info # ["2005年8月", "2018年12月11日", "12月末日", "化粧品と健康食品に特化したＥＣマーケティング支援が柱。従来型のマーケティング支援も"]
      end

      # ---transaction---

      def self.get_transaction_url(company_code)
        "https://stocks.finance.yahoo.co.jp/stocks/detail/?code=#{company_code}"
      end

      def self.get_transactions_url(company_code, start_date, end_date, page)
        "https://info.finance.yahoo.co.jp/history/?code=#{company_code}&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
      end

      def self.get_transactions_info(company_code, page)
        transactions_url = get_transactions_url(company_code, scrape_start_date, scrape_end_date, page)
        transactions_doc = get_content(transactions_url, :short)
        transactions_info = get_info(transactions_doc)
        transactions_info
      end

      def self.get_transaction_line(transaction_info, company_code, page, index)
        # transaction[0] = company_code
        # transaction[1] = date
        # transaction[2] = opening_price
        # transaction[3] = high_price
        # transaction[4] = low_price
        # transaction[5] = closing_price
        # transaction[6] = turnover
        # transaction[7] = vwap
        # transaction[8] = tick_count
        # transaction[9] = trading_value

        transaction_line = []
        transaction_line << company_code
        transaction_data = get_data(transaction_info)
        return nil unless transaction_data.size == 7 # この条件なんとかしたい (分割: 1株 -> 1.1株)など分割条件のデータを除外
        transaction_line << trim_to_date(transaction_data[0])
        transaction_data.collect!{|data| data == '---' ? transaction_data[4] : data} if transaction_data.include?('---') # 始値---(非表示)がある場合、そこには終値を入れる

        # stock split adjust
        (1..6).each{|index| transaction_data[index] = trim_to_f(transaction_data[index])}
        if transaction_data[4] != transaction_data[6]
          scale = (transaction_data[4] / transaction_data[6])
          (1..4).each{|index| transaction_line << (transaction_data[index] / scale).to_i}
          transaction_line << transaction_data[5].to_i
        else
          (1..5).each{|index| transaction_line << transaction_data[index].to_i}
        end
        if page == 1 && index == 0
          transaction_date = trim_to_date(transaction_data[0])
          transaction_line += Clawler::Sources::Kabutan.get_some_info(company_code, transaction_date) # vwap, tick_count
          transaction_line += Clawler::Sources::Yahoo.get_some_info(company_code, transaction_date) # trading_value
        end
        transaction_line
      end

      def self.get_some_info(company_code, line_date)
        transaction_info = []
        transaction_url = get_transaction_url(company_code)
        transaction_doc = get_content(transaction_url, :short)
        date_ary = transaction_doc.xpath('//div[@class="innerDate"]/div')[5].css('dd/span').text.split(/[^0-9]/)[1..-1].try(:map, &:to_i)
        return [nil] if ((date_ary.nil?) || (date_ary != [line_date.month, line_date.day]))
        transaction_info << trim_to_i(transaction_doc.xpath('//div[@class="innerDate"]/div')[5].css('dd/strong').text.strip + '000')
        transaction_info
      end

      # ---credit_deal---

      def self.get_credit_deals_url(company_code, start_date, end_date, page)
        "https://info.finance.yahoo.co.jp/history/margin/?code=#{company_code}&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
      end

      def self.get_credit_deals_info(company_code, page)
        credit_deals_url = get_credit_deals_url(company_code, scrape_start_date, scrape_end_date, page)
        credit_deals_doc = get_content(credit_deals_url, :short)
        credit_deals_info = get_info(credit_deals_doc)
        credit_deals_info
      end

      def self.get_credit_deal_line(credit_deal_info, company_code)
        credit_deal_line = []
        credit_deal_data = get_data(credit_deal_info)
        credit_deal_line << trim_to_date(credit_deal_data[0])
        (1..4).each{|index| credit_deal_line << trim_to_i(credit_deal_data[index])}
        credit_deal_line << trim_to_f(credit_deal_data[5])
        credit_deal_line.unshift(company_code)
        credit_deal_line
      end

      # ---foreign_exchange---

      def self.get_foreign_exchanges_url(currency, start_date, end_date, page)
        "https://info.finance.yahoo.co.jp/history/?code=#{currency.to_s.upcase}%3DX&sy=#{start_date.year}&sm=#{start_date.month}&sd=#{start_date.day}&ey=#{end_date.year}&em=#{end_date.month}&ed=#{end_date.day}&tm=d&p=#{page}"
      end

      def self.get_foreign_exchanges_info(currency, page)
        foreign_exchanges_url = get_foreign_exchanges_url(currency, scrape_start_date, scrape_end_date, page)
        foreign_exchanges_doc = get_content(foreign_exchanges_url, :short)
        foreign_exchanges_info = get_info(foreign_exchanges_doc)
      end

      def self.get_foreign_exchange_line(foreign_exchange_info, currency_code)
        foreign_exchange_line = []
        foreign_exchange_data = get_data(foreign_exchange_info)
        foreign_exchange_line << trim_to_date(foreign_exchange_data[0])
        (1..4).each{|index| foreign_exchange_line << trim_to_f(foreign_exchange_data[index])}
        foreign_exchange_line.unshift(currency_code)
        foreign_exchange_line
      end

      # ---trend---

      def self.get_words(texts)
        words = []
        texts.each do |text|
          params = "?appid=#{YAHOO_APP_ID}&sentence=#{URI.encode(text)}"
          url = EXTRACT_API_BASE_URL + params
          wait_interval(:short)
          response = open(url)

          doc = REXML::Document.new(response).elements['ResultSet/']
          doc.elements.each('Result') do |element|
            phrase = element.elements['Keyphrase'][0].to_s
            score = element.elements['Score'][0].to_s.to_i
            words << [phrase, score] unless words.map{|ary| ary[0]}.include?(phrase)
          end
        end
        words
      end

      def self.process_line(words_scores)
        ignored_tags = ::Tag.where(tag_type: c(:tag_type, :ignore)).pluck(:name)
        words = words_scores.group_by{|word_score| word_score[0]}.map{|word, lines| [word, lines.transpose[1]
        .inject{|sum, score| sum += score}]}.sort_by{|word_score| word_score[1]}.reverse.map{|word_score| word_score[0]}.flatten
        (words - ignored_tags)[0..500]
      end

      # ---common---

      def self.get_info(doc)
        doc.xpath('//table[@class="boardFin yjSt marB6"]/tr')[1..-1]
      end

      def self.get_data(doc)
        doc.css('td').map(&:text)
      end

    end
  end
end