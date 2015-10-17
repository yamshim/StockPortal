class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.string :url
      t.string :source
      t.date :date

      t.timestamps null: false
    end
  end
end
