class AddIndexToCreditDeals < ActiveRecord::Migration
  def change
    add_index :credit_deals, [:company_id, :date], unique: true
  end
end
