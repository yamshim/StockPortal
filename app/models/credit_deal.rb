class CreditDeal < ActiveRecord::Base
  belongs_to :company

  validates :date, :selling_balance, :debt_balance, :margin_ratio, :company_id, presence: true
  validates :date, uniqueness: {scope: :company_id}
  validates :selling_balance, :debt_balance, :margin_ratio, :company_id, numericality: true
end
