class AddPerformanceMetricsToSoftwares < ActiveRecord::Migration[7.1]
  def change
    add_column :softwares, :performance_rating, :float, comment: "Performance rating on exponential scale"
    add_column :softwares, :efficiency_score, :float, comment: "Efficiency calculated using logarithmic functions"
    add_column :softwares, :processing_factor, :float, comment: "Processing time factor"
  end
end
