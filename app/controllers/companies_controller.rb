class CompaniesController < ApplicationController

  def index
    @company_code = params[:id].to_i
    @company = Company.find_by_company_code(@company_code)
    #@transactions = @company.transactions.order(:date).pluck(:date, :closing_price).map{|line| [line[0].to_s, line[1]]}.unshift(['Date', 'Closing_price'])
    @transactions = @company.transactions.order(:date).pluck(:date, :closing_price, :id).map{|line| [line[0].to_s, line[1], line[2]]}.unshift(['Date', 'Closing_price', 'Id'])
    render 'index'
  end

end
