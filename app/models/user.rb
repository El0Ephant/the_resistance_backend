class User < ApplicationRecord
  validates :nickname, :email, :password_digest, presence:  true
  validates :email, :login, uniqueness: true
  has_many :participations
  has_many :games, through: :participations
  devise :database_authenticatable, :registerable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

end