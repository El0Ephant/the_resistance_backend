require "active_support/core_ext/hash"

module RedisHelper

  GAME_STATE = {
    Initial: 0,
    CandidatesSelection: 1,
    #...
  }

  MISSION_STATE = {
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "Success": 0,
    "Failure": 1,
  }

  def create_game_state(game_id, *players)
    state_hash = Kredis.hash "#state{game_id}", typed: :integer
    state_hash.value = {
      state: GAME_STATE["Initial"],
      mission1: MISSION_STATE["2"],
      mission2: MISSION_STATE["3"],
      mission3: MISSION_STATE["4"],
      mission4: MISSION_STATE["3"],
      mission5: MISSION_STATE["4"],
      current_vote: 0,
      leader: 0, #id
    }

    players.each do |player_id|
      state_hash.update(player_id => 0) # Для будущего голосования за кандидатов
    end

    Kredis.list "#candidates{game_id}"
    Kredis.list "#secret_votes{game_id}"

    roles_hash = Kredis.hash "#secret_votes{game_id}", typed: :integer
    players.each do |player_id|
      roles_hash.update(player_id => 0) # Выдать рандомную роль
    end

  end

  def vote(user_id, choise)

  end

end
