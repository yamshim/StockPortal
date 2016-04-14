# coding: utf-8

class Segment
  require 'pdf-reader'
  require 'open-uri'
  require 'pry'
  require 'nokogiri'

  def self.execute
    company_codes = Company.select(:company_code).map(&:company_code).sort
    [1301].each do |company_code|
      begin
        puts company_code
        puts "\n\n\n\n\n\n\n"

        sleep(0.1)
        doc = Nokogiri::HTML.parse(open("http://advance.quote.nomura.co.jp/meigara/nomura2/users/asp/bs_list5r.asp?KEY1=#{company_code}"), nil, 'utf-8')
        part_url = doc.xpath('//table[@class="def"]').css('td/a').select{|node| node.text !~ /第１四半期|第２四半期|第３四半期|訂正/}[0].attribute('href').value
        url = 'http://advance.quote.nomura.co.jp/meigara/nomura2/' + part_url.slice(/pdfdoc.+/)
        reader = PDF::Reader.new(open(url, 'rb'))
        binding.pry

        root_page_index = reader.pages.map.with_index{|page, index| index if page.text =~ /財務諸表に関する注記事項/}.compact.last
        seg_indexies = reader.pages[root_page_index..-1].map.with_index do |page, page_index|
          seg_text_lines = page.text.split("\n")
          seg_text_lines.delete('')
          line_indexies = seg_text_lines.map.with_index{|line, line_index| line_index if line =~ /セグメント利益.+(\d){3}.+(\d){3}.+(\d){3}/}.compact
          line_indexies.any? ? [page_index, line_indexies] : nil
        end
        lines = []

        if (seg_indexies = seg_indexies.compact).size == 1
          seg_page_index = seg_indexies[0][0]
          former_seg_line_index = seg_indexies[0][1][0]
          latter_seg_line_index = seg_indexies[0][1][1]

          former_seg_text_lines =  reader.pages[root_page_index + seg_page_index].text.split("\n")
          former_seg_text_lines.delete('')
          # former_seg_sale_cols =  former_seg_text_lines[former_seg_line_index - 1].split(' ').map{|col| col.gsub('△', '*-')}
          # former_seg_profit_cols =  former_seg_text_lines[former_seg_line_index].split(' ').map{|col| col.gsub('△', '*-')}

          ((former_seg_line_index - 10)..(former_seg_line_index + 5)).each do |index|
            line = former_seg_text_lines[index].try(:split, ' ').try(:map, &Proc.new {|col| col.gsub('△', '*-')}).try(:map, &Proc.new {|col| col.split('*')}).try(:flatten, 1)
            line.delete('')
            lines << line
            p line
          end
          File.open("#{Rails.root}/tmp/file/segment_#{company_code}.text", 'wb') do |writer|
            lines.each{|line| writer << line; writer << "\n"}
          end
          puts "\n\n\n\n\n\n\n"
        elsif (seg_indexies = seg_indexies.compact).size == 2
          former_seg_page_index = seg_indexies[0][0]
          former_seg_line_index = seg_indexies[0][1][0]

          former_seg_text_lines =  reader.pages[root_page_index + former_seg_page_index].text.split("\n")
          former_seg_text_lines.delete('')

          ((former_seg_line_index - 15)..(former_seg_line_index + 10)).each do |index|
            binding.pry if index == former_seg_line_index - 1
            line = former_seg_text_lines[index].try(:split, ' ').try(:map, &Proc.new {|col| col.gsub('△', '*-')}).try(:map, &Proc.new {|col| col.split('*')}).try(:flatten, 1)
            line.delete('')
            lines << line
            p line
          end
          File.open("#{Rails.root}/tmp/file/segment_#{company_code}.text", 'wb') do |writer|
            lines.each{|line| writer << line; writer << "\n"}
          end
          puts "\n\n\n\n\n\n\n"

          # latter_seg_page_index = seg_indexies[1][0]
          # latter_seg_line_index = seg_indexies[1][1][0]

        end
      rescue => ex
        File.open("#{Rails.root}/tmp/file/segment_#{company_code}.text", 'wb') do |writer|
          writer << ex
        end
        p ex
        p company_code
        puts "\n\n\n\n\n\n\n"
      end
    end
  end


  
end


