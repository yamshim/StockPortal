class RemoveIndexToArticles < ActiveRecord::Migration
  def change
    remove_index :articles, :url
  end
end
