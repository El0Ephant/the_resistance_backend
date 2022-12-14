class Participation < ApplicationRecord
  GOOD_ROLES = [:Merlin, :Percival, :Loyal]
  EVIL_ROLES = [:Mordred, :Oberon, :Assassin, :Morgana, :Evil]

  enum :role, GOOD_ROLES + EVIL_ROLES
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