class AddDimensionsAndMetricsToRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :records, :width, :float, comment: "Width dimension in mm"
    add_column :records, :height, :float, comment: "Height dimension in mm"
    add_column :records, :depth, :float, comment: "Depth dimension in mm"
    add_column :records, :rotation_angle, :float, comment: "Rotation angle in degrees"
    add_column :records, :complexity_score, :float, comment: "Calculated complexity score using logarithmic scale"
  end
end
