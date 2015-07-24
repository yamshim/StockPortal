class CreateCompaniesTags < ActiveRecord::Migration
  def change
    create_table :companies_tags, id: false do |t|
      t.integer :company_id
      t.integer :tag_id
    end
  end
end
