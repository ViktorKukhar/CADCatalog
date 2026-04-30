class CreateJoinTableCategoryRecord < ActiveRecord::Migration[7.1]
  def change
    create_join_table :categories, :records do |t|
      t.index [:category_id, :record_id], unique: true
      t.index [:record_id, :category_id]
    end
  end
end
