class CreateCollections < ActiveRecord::Migration[7.1]
  def change
    create_table :collections do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :public, default: false, null: false
      t.timestamps
    end

    add_index :collections, [:user_id, :name], unique: true
  end
end
