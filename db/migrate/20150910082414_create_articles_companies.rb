class CreateArticlesCompanies < ActiveRecord::Migration
  def change
    create_table :articles_companies do |t|
      t.integer :article_id
      t.integer :company_id
    end
  end
end
