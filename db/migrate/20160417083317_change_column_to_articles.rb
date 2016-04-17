class ChangeColumnToArticles < ActiveRecord::Migration
  def change
    remove_index :articles, :url
    change_column :articles, :url, :text, limit: 500
    add_index :articles, :url, unique: true, length: 255
  end
end
