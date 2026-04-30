class CreateJoinTableCollectionRecord < ActiveRecord::Migration[7.1]
  def change
    create_join_table :collections, :records do |t|
      t.index [:collection_id, :record_id], unique: true
      t.index [:record_id, :collection_id]
    end
  end
end
