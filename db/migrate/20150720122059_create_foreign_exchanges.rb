class CreateForeignExchanges < ActiveRecord::Migration
  def change
    create_table :foreign_exchanges do |t|
      t.date :date
      t.float :opening_price
      t.float :high_price
      t.float :low_price
      t.float :closing_price
      t.integer :currency_code

      t.timestamps null: false
    end
  end
end
