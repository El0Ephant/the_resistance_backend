class Participation < ApplicationRecord
  GOOD_ROLES = [:merlin, :percival, :good_knight]
  EVIL_ROLES = [:mordred, :oberon, :assasin, :morgana, :evil_knight]

  enum :role, GOOD_ROLES.concat(EVIL_ROLES)
  validates :user_id, :game_id, :role, presence: true
  belongs_to :game
  belongs_to :user

  def evil?
    EVIL_ROLES.include? role.to_sym
  end

  def good?
    GOOD_ROLES.include? role.to_sym
  end
end