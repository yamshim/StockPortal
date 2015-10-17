class Transaction < ActiveRecord::Base
  belongs_to :company

  validates :date, :high_price, :low_price, :opening_price, :closing_price, :turnover, :company_id, presence: true
  validates :date, uniqueness: {scope: :company_id}
  validates :high_price, :low_price, :opening_price, :closing_price, :turnover, :company_id, :vwap, numericality: {allow_nil: true}
end
