class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Records: support the complexity/creation scopes and title searches efficiently
    add_index :records, :title
    add_index :records, :complexity_score
    add_index :records, :created_at

    # Softwares: enforce uniqueness at DB level (model validates but no DB index existed)
    # and support performance/efficiency ordering scopes
    add_index :softwares, :name, unique: true
    add_index :softwares, :performance_rating
    add_index :softwares, :efficiency_score
  end
end
