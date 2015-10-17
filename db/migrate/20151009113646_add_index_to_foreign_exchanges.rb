class AddIndexToForeignExchanges < ActiveRecord::Migration
  def change
    add_index :foreign_exchanges, [:currency_code, :date], unique: true
  end
end
