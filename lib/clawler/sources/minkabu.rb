# coding: utf-8

module Clawler
  module Sources
    module Minkabu
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://minkabu.jp'
      end

      def self.get_brackets_url(identifier, page)
        home_url + "/stock/#{identifier}/timeline?fp=#{page}#fourvalue"
      end

      def self.get_brackets_info(identifier, page)
        brackets_url = get_brackets_url(identifier, page)
        brackets_doc = get_content(brackets_url, :short)
        brackets_info = brackets_doc.xpath('//table[@id="fourvalue_timeline"]/tr')[1..-1]
        brackets_info
      end

      def self.get_bracket_line(bracket_info, bracket_code)
        bracket_line = []
        bracket_data = bracket_info.css('td').map(&:text)
        bracket_line << trim_to_date(bracket_data[0])
        (1..5).each{|index| bracket_data[index] = trim_to_f(bracket_data[index])}
        if bracket_data[4] != bracket_data[5]
          scale = (bracket_data[4] / bracket_data[5])
          (1..4).each{|index| bracket_line << (bracket_data[index] / scale)}
        else
          (1..4).each{|index| bracket_line << bracket_data[index]}
        end
        bracket_line << trim_to_i(bracket_data[6])
        bracket_line.unshift(bracket_code)
        bracket_line
      end

    end
  end
end