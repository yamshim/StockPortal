class CreateTrends < ActiveRecord::Migration
  def change
    create_table :trends do |t|
      t.date :date

      t.timestamps null: false
    end
  end
end
