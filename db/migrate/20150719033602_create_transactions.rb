class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.date :date
      t.integer :high_price
      t.integer :low_price
      t.integer :opening_price
      t.integer :closing_price
      t.integer :turnover
      t.float :vwap
      t.integer :company_id

      t.timestamps null: false
    end
  end
end
