class User < ApplicationRecord
  validates :nickname, :email, :password_digest, presence:  true
  validates :email, :login, uniqueness: true
  has_many :participations
  has_many :games, through: :participations

end