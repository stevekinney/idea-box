class Idea < ActiveRecord::Base
  validates :title, presence: true

  enum quality: [:swill, :plausible, :genius]
end
