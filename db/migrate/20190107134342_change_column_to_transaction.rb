class ChangeColumnToTransaction < ActiveRecord::Migration
  def change
    change_column :transactions, :trading_value, :integer, limit: 5
  end
end
