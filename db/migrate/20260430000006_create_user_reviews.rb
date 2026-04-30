class CreateUserReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :user_reviews do |t|
      t.references :record, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.timestamps
    end

    # One review per user per record — enforced at both DB and model level
    add_index :user_reviews, [:record_id, :user_id], unique: true
    add_check_constraint :user_reviews, 'rating >= 1 AND rating <= 5', name: 'user_reviews_rating_range'
  end
end
