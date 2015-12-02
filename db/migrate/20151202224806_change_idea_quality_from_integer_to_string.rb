class ChangeIdeaQualityFromIntegerToString < ActiveRecord::Migration
  def change
    change_column :ideas, :quality, :string, default: "swill"
  end
end
