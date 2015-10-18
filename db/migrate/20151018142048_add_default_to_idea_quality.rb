class AddDefaultToIdeaQuality < ActiveRecord::Migration
  def change
    change_column :ideas, :quality, :integer, default: 0
  end
end
