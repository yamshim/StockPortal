class AddIndexToCommodities < ActiveRecord::Migration
  def change
    add_index :commodities, [:commodity_code, :date], unique: true
  end
end
