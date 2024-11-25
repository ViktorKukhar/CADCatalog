class CreateJoinTableRecordSoftware < ActiveRecord::Migration[7.1]
  def change
    create_join_table :records, :softwares do |t|
      t.index [:record_id, :software_id], unique: true
      t.index [:software_id, :record_id], unique: true
    end
  end
end
