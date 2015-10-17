class AddIndexToBrackets < ActiveRecord::Migration
  def change
    add_index :brackets, [:bracket_code, :date], unique: true
  end
end
