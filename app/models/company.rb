class Company < ActiveRecord::Base
  has_many :transactions, dependent: :delete_all
  has_many :credit_deals, dependent: :delete_all
  has_and_belongs_to_many :tags
  # バリデーション
end
