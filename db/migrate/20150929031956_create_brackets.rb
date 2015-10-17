class CreateBrackets < ActiveRecord::Migration
  def change
    create_table :brackets do |t|
      t.integer :bracket_code
      t.float :opening_price
      t.float :high_price
      t.float :low_price
      t.float :closing_price
      t.date :date
      t.integer :turnover, limit: 8

      t.timestamps null: false
    end
  end
end
