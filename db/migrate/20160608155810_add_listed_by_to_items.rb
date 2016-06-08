class AddListedByToItems < ActiveRecord::Migration
  def change
    add_column :items, :listed_by_id, :string
  end
end
