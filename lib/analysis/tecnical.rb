# coding: utf-8

module Analysis
  class Tecnical

    def self.hoge
      # text = open('/Users/akasatana/Downloads/transaction_lines_3966 (7).csv', encoding:'Shift_JIS:UTF-8')
      lines = CSV.parse(text).reverse
      lines.each_with_index do |line, index|
        pressure = 0
        lines[index..(index + 29)].each do |obj_line|
          if ((line[5].to_f - obj_line[7].to_f) / obj_line[7].to_f * 100) >= 5
            pressure += obj_line[6].to_f
          elsif ((line[5].to_f - obj_line[7].to_f) / obj_line[7].to_f * 100) <= -5
            pressure += obj_line[6].to_f
          end
        end
        line << pressure
      end
      lines = lines.reverse
      @days = lines.map{|line| line[1]}
      @closing_price = lines.map{|line| line[5]}
      @pressure = lines.map{|line| line[-1]}
    end

  end
end