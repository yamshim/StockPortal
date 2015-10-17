class AddIndexToTransactions < ActiveRecord::Migration
  def change
    add_index :transactions, [:company_id, :date], unique: true
  end
end
