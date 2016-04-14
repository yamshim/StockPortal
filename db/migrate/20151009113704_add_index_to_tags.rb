class AddIndexToTags < ActiveRecord::Migration
  def change
    # add_index :tags, [:tag_type, :name], unique: true
  end
end
