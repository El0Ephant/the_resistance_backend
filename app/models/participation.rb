class Participation < ApplicationRecord
  enum :role, [:merlin, :percival, :good_knight, :mordred, :oberon, :assasin, :morgana, :evil_knight]
  validates :user_id, :game_id, :role, presence: true
  belongs_to :game
  belongs_to :user

end