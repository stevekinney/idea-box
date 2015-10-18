class CreateIdeas < ActiveRecord::Migration
  def change
    create_table :ideas do |t|
      t.string :title
      t.text :body
      t.integer :quality

      t.timestamps null: false
    end
  end
end
