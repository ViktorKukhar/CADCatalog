class CreateSoftwares < ActiveRecord::Migration[7.1]
  def change
    create_table :softwares do |t|
      t.string :name

      t.timestamps
    end
  end
end
