class CreateCommodities < ActiveRecord::Migration
  def change
    create_table :commodities do |t|
      t.date :date
      t.integer :commodity_code
      t.float :opening_price
      t.float :high_price
      t.float :low_price
      t.float :closing_price

      t.timestamps null: false
    end
  end
end
