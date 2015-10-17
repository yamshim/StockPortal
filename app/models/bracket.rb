class Bracket < ActiveRecord::Base
  validates :bracket_code, :opening_price, :high_price, :low_price, :closing_price, :date, :turnover, presence: true
  validates :date, uniqueness: {scope: :bracket_code}
  validates :bracket_code, :opening_price, :high_price, :low_price, :closing_price, :turnover, numericality: true
end