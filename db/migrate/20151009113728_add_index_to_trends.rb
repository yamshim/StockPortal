class AddIndexToTrends < ActiveRecord::Migration
  def change
    add_index :trends, :date, unique: true
  end
end
