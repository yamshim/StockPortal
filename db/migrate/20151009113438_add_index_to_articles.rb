class AddIndexToArticles < ActiveRecord::Migration
  def change
    add_index :articles, :url, unique: true
  end
end
