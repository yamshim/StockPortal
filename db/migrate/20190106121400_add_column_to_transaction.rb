class AddColumnToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :tick_count, :integer
    add_column :transactions, :trading_value, :integer
  end
end
