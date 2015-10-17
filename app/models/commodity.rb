class Commodity < ActiveRecord::Base
  validates :date, :commodity_code, :opening_price, :high_price, :low_price, :closing_price, presence: true
  validates :date, uniqueness: {scope: :commodity_code}
  validates :commodity_code, :opening_price, :high_price, :low_price, :closing_price, numericality: true
end
