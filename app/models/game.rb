class Game < ApplicationRecord
  WINNERS = [:good, :evil]

  enum :winner, WINNERS
  validates :winner, :mission_1, :mission_2, :mission_3, presence: true
  has_many :participations
  has_many :users, through: :participations

  def self.page(page, per_page)
    self.order(created_at: :desc).offset((page - 1) * per_page).limit per_page
  end

  def good_won?
    winner.to_sym == :good
  end

  def evil_won?
    winner.to_sym == :evil
  end
end