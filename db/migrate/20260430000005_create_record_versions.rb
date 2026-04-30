class CreateRecordVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :record_versions do |t|
      t.references :record, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :version_number, null: false
      t.text :change_log
      # Dimension snapshot — captures the exact geometry at time of version commit
      t.float :width
      t.float :height
      t.float :depth
      t.float :rotation_angle
      t.float :complexity_score
      t.timestamps
    end

    add_index :record_versions, [:record_id, :version_number], unique: true
  end
end
