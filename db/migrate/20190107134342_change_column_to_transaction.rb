class ChangeColumnToTransaction < ActiveRecord::Migration
  # def change
  #   change_column :transactions, :trading_value, :integer, limit: 5
  # end
  def up
    change_column :transactions, :trading_value, :integer, limit: 5
  end

  def down
    change_column :transactions, :trading_value, :integer
  end
end
