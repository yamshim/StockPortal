class CompaniesController < ApplicationController

  def index
    @company_code = params[:id].to_i
    @company = Company.find_by_company_code(@company_code)

    # Closing_price and Pressure
    @pressure_lines = @company.transactions.order(:date).where(date: '2019-2-1'..'2020-1-8').pluck(:date, :closing_price, :vwap, :turnover).reverse
    @pressure_lines.each_with_index do |line, index|
      pressure = 0
      @pressure_lines[index..(index + 40)].each do |obj_line|
        if ((line[1].to_f - obj_line[2].to_f) / obj_line[2].to_f * 100) >= 5
          pressure += obj_line[3].to_f
        elsif ((line[1].to_f - obj_line[2].to_f) / obj_line[2].to_f * 100) <= -10
          pressure += obj_line[3].to_f
        end
      end
      @pressure_lines[index] << pressure
    end
    @pressure_lines = @pressure_lines.reverse.map{|line| [line[0].to_s, line[1], line[4]]}.unshift(['Date', 'Closing_price', 'Pressure'])


    # Closing_price and Article
    @price_lines = @company.transactions.order(:date).where(date: '2016-1-1'..'2020-1-8').pluck(:date, :closing_price)
    @article_lines = @company.articles.order(:date).pluck(:date, :title, :url).group_by{|line| line[0]}
    @price_lines.each_with_index do |price_line, price_index|
      @article_lines.each do |article_line|
        if price_line[0] == article_line[0]
          @price_lines[price_index] << article_line[1].size
          @price_lines[price_index] << article_line[1].map{|line| [line[1], line[2]]}
        end
      end
      if @price_lines[price_index].size == 2
        @price_lines[price_index] << 0
        @price_lines[price_index] << []
      end
    end
    @article_lines = @price_lines.map{|line| [line[0].to_s, line[1], line[2]]}.unshift(['Date', 'Closing_price', 'Article'])



   









    render 'index'
  end

end
