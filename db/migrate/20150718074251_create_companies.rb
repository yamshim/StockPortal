class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.integer :company_code
      t.string :name
      t.text :description
      t.integer :accounting_period
      t.integer :trading_unit
      t.integer :industry_code
      t.date :established_date
      t.date :listed_date
      t.integer :market_code
      t.integer :country_code
      t.string :url

      t.timestamps null: false
    end
  end
end
