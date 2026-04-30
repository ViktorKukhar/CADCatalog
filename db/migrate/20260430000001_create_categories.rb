class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.references :parent_category, null: true, foreign_key: { to_table: :categories }
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, [:parent_category_id, :position]
  end
end
