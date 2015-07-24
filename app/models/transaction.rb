class Transaction < ActiveRecord::Base
  belongs_to :company
  # バリデーション
end
