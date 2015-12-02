class Idea < ActiveRecord::Base
  validates :title, :body, presence: true

  enum quality: [:swill, :plausible, :genius]
end
