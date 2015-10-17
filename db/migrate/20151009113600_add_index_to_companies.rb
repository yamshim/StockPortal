class AddIndexToCompanies < ActiveRecord::Migration
  def change
    add_index :companies, :company_code, unique: true
  end
end
