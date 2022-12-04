class Game < ApplicationRecord
  enum :winner, [:goodness, :evil]
  validates :winner, :mission_1, :mission_2, :mission_3, presence: true
  has_many :participations
  has_many :users, through: :participations

end