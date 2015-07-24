class CreateCreditDeals < ActiveRecord::Migration
  def change
    create_table :credit_deals do |t|
      t.date :date
      t.integer :selling_balance
      t.integer :debt_balance
      t.float :margin_ratio
      t.integer :company_id

      t.timestamps null: false
    end
  end
end
