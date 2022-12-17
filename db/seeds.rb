# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Game.destroy_all
User.destroy_all
Participation.destroy_all

User.create!([
  {email:'test@email.com', login: 'login', nickname: 'nickname', password: 'password'},
  {email:'test1@email.com', login: 'login1', nickname: 'nickname1', password: 'password1'},
  {email:'test2@email.com', login: 'login2', nickname: 'nickname2', password: 'password1'},
])
Game.create!([
  {winner: :good, murdered_id: User.second.id, mission_1: true, mission_2: false, mission_3: true, mission_4: true, created_at: DateTime.new(2022, 10, 13, 4, 5)},
  {winner: :evil, murdered_id: User.first.id, mission_1: true, mission_2: true, mission_3: true, created_at: DateTime.new(2022, 10, 22, 8, 19)},
  {winner: :evil, mission_1: false, mission_2: false, mission_3: true, mission_4: false, created_at: DateTime.new(2022, 11, 14, 4, 8)},
  {winner: :good, murdered_id: User.third.id, mission_1: true, mission_2: true, mission_3: true, mission_4: true, created_at: DateTime.new(2022, 10, 16, 6, 5)},
  {winner: :good, murdered_id: User.second.id, mission_1: true, mission_2: true, mission_3: true, mission_4: true, created_at: DateTime.new(2022, 10, 27, 2, 47)},
  {winner: :good, mission_1: false, mission_2: true, mission_3: false, mission_4: true, mission_5: false, created_at: DateTime.new(2022, 9, 13, 22, 13)},
  {winner: :evil, murdered_id: User.second.id, mission_1: true, mission_2: true, mission_3: true, created_at: DateTime.new(2022, 10, 13, 14, 15)},
  {winner: :good, mission_1: true, mission_2: false, mission_3: false, mission_4: false, created_at: DateTime.new(2022, 8, 9, 6, 8)},
  {winner: :evil, murdered_id: User.second.id, mission_1: true, mission_2: true, mission_3: false, mission_4: true, created_at: DateTime.new(2022, 10, 15, 19, 11)},
])

game_ids = Game.all.map &:id

Participation.create!([
  {user_id: User.first.id, game_id: game_ids[0], role: 0},
  {user_id: User.first.id, game_id: game_ids[1], role: 1},
  {user_id: User.first.id, game_id: game_ids[2], role: 2},
  {user_id: User.first.id, game_id: game_ids[3], role: 3},
  {user_id: User.first.id, game_id: game_ids[4], role: 4},
  {user_id: User.first.id, game_id: game_ids[5], role: 5},
  {user_id: User.first.id, game_id: game_ids[6], role: 6},
  {user_id: User.first.id, game_id: game_ids[7], role: 7},
  {user_id: User.first.id, game_id: game_ids[8], role: 3},
])