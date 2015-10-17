class CreateTagsTrends < ActiveRecord::Migration
  def change
    create_table :tags_trends do |t|
      t.integer :trend_id
      t.integer :tag_id
    end
  end
end
