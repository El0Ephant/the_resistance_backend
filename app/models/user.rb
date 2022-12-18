class User < ApplicationRecord
  validates :login, :email, :encrypted_password, presence: true
  validates :login, :email, uniqueness: true
  has_many :participations
  has_many :games, through: :participations
  devise :database_authenticatable, :registerable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

end
