class ForeignExchange < ActiveRecord::Base
  validates :currency_code, :opening_price, :high_price, :low_price, :closing_price, :date, presence: true
  validates :date, uniqueness: {scope: :currency_code}
  validates :currency_code, :opening_price, :high_price, :low_price, :closing_price, numericality: true
end
