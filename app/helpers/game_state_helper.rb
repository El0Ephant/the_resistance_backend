module GameStateHelper
  module State
    WAITING = "waiting"
    PICK_CANDIDATES = "pickCandidates"
    VOTE_FOR_CANDIDATES = "voteForCandidates"
    VOTE_FOR_CANDIDATES_REVEALED = "voteForCandidatesRevealed"
    VOTE_FOR_RESULT = "voteForResult"
    VOTE_FOR_RESULT_REVEALED = "voteForResultRevealed"

    PICK_PLAYER_FOR_MURDER = "pickPlayerForMurder"

    BAD_FINAL = "badFinal"
    GOOD_FINAL = "goodFinal"
  end

  module Role
    LOYAL = "Loyal"
    EVIL = "Evil"

    MERLIN = "Merlin"
    PERCIVAL = "Percival"

    ASSASSIN = "Assassin"
    MORGANA = "Morgana"
    MORDRED = "Mordred"
    OBERON = "Oberon"
  end

  module Mission
    REQUIRED2 = 2
    REQUIRED3 = 3
    REQUIRED4 = 4
    REQUIRED5 = 5

    WIN = "Win"
    LOOSE = "Loose"
  end

  def create_game(game_id, player_count, roles)
    game_state = GameState.create(id: game_id, player_count: player_count, roles: roles)
    game_state.missions = case player_count
                          when 5
                            [2, 3, 2, 3, 3]
                          when 6
                            [2, 3, 4, 3, 4]
                          when 7
                            [2, 3, 3, 4, 4]
                          when 8
                            [3, 4, 4, 5, 5]
                          when 9
                            [3, 4, 4, 5, 5]
                          when 10
                            [3, 4, 4, 5, 5]
                          else
                            [2, 2, 2, 2, 2] # для тестирования
                          end
  end

  def delete_game(game_id)
    GameState.find(game_id).delete
  end

  def is_here?(game_id, user_id)
    game_state = GameState.find(game_id)
    game_state.players.include?(user_id)
  end

  def is_admin?(game_id, user_id)
    game_state = GameState.find(game_id)
    game_state.admin_id == user_id
  end

  def is_leader?(game_id, user_id)
    game_state = GameState.find(game_id)
    game_state.leader_id == user_id
  end

  def right_role?(game_id, user_id, *roles)
    game_state = GameState.find(game_id)
    roles.include?(game_state.player_roles[user_id.to_s])
  end

  def right_state?(game_id, state)
    game_state = GameState.find(game_id)
    game_state.state == state
    create_hash(game_state)
  end

  def start_game(game_id)
    game_state = GameState.find(game_id)
    players = game_state.players
    roles = game_state.roles
    game_state.players_roles = players.zip(roles.shuffle).to_h
    game_state.leader_id = game_state.players.sample
    game_state.save
    create_hash(game_state)
  end

  def take_seat(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.players << player_id
    game_state.save
    create_hash(game_state)
  end

  def free_up_seat(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.players.delete(player_id)
    game_state.save
    create_hash(game_state)
  end

  def hand_over_leadership(game_id)
    game_state = GameState.find(game_id)
    players = game_state.players
    game_state.leader_id = players.sample
    game_state.save
    create_hash(game_state)
  end

  def pick_player_for_mission(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.candidates << player_id
    game_state.save
    create_hash(game_state)
  end

  def unpick_player_for_mission(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.candidates.delete(player_id)
    game_state.save
    create_hash(game_state)
  end

  def confirm_team(game_id)
    game_state = GameState.find(game_id)
    if game_state.missions[game_state.current_mission] == game_state.candidates.size
      if game_state.current_vote == 5
        game_state.current_vote = 1
        game_state.state = State::VOTE_FOR_RESULT
        game_state.save
        return create_hash(game_state)
      else
        game_state.state = State::VOTE_FOR_CANDIDATES
      end
    end
    game_state.save
    create_hash(game_state)
  end

  def vote_for_candidates(game_id, player_id, vote)
    game_state = GameState.find(game_id)
    GameState.with_session do |s|
      s.start_transaction
      game_state.votes_for_candidates[player_id.to_s] = vote
      if game_state.votes_for_candidates.size == game_state.players_count
        game_state.state = State::VOTE_FOR_CANDIDATES_REVEALED
      end
      game_state.save
      s.commit_transaction
    end
    create_hash(game_state)
  end

  def after_vote(game_id)
    game_state = GameState.find(game_id)

    result = 0
    game_state.votes_for_candidates.values.each do |value|
      result += value ? 1 : -1
    end

    if result.positive?
      game_state.current_vote = 1
      game_state.state = State::VOTE_FOR_RESULT
    else
      game_state.current_vote += 1
      game_state.candidates = []
      game_state.votes_for_candidates = {}
      game_state.state = State::VOTE_FOR_CANDIDATES
    end
    game_state.save
    create_hash(game_state)
  end

  def vote_for_result(game_id, player_id, vote)
    game_state = GameState.find(game_id)
    GameState.with_session do |s|
      s.start_transaction

      if game_state.candidates.include?(player_id)
        game_state.votes_for_result[player_id] = vote
      end
      if game_state.votes_for_result.size == game_state.candidates.size
        game_state.state = State::VOTE_FOR_RESULT_REVEALED
        game_state.missions[game_state.current_mission] = game_state.votes_for_result.values.all? ?
                                                            Mission::WIN
                                                            :
                                                            Mission::LOOSE
      end
      game_state.save
      s.commit_transaction
    end
    create_hash(game_state)
  end

  def end_step(game_id)
    game_state = GameState.find(game_id)

    missions = game_state.missions
    tally = missions.tally
    if tally[Mission::WIN] == 3
      game_state.state = State::PICK_PLAYER_FOR_MURDER
      game_state.save
      return create_hash(game_state)
    end

    if tally[Mission::LOOSE] == 3
      game_state.state = State::BAD_FINAL
      game_state.save
      return create_hash(game_state)
    end

    game_state.current_mission += 1

    game_state.state = State::PICK_CANDIDATES
    game_state.candidates = []
    game_state.votes_for_candidates = {}
    game_state.votes_for_result = {}
    game_state.leader_id = game_state.players.sample
    game_state.save
    create_hash(game_state)
  end

  def pick_player_for_murder(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.murdered_id = player_id
    game_state.save
    create_hash(game_state)
  end

  def unpick_player_for_murder(game_id, player_id)
    game_state = GameState.find(game_id)
    game_state.murdered_id = nil
    game_state.save
    create_hash(game_state)
  end

  def confirm_murder(game_id)
    game_state = GameState.find(game_id)
    if game_state.murdered_id != nil
      if game_state.player_roles[game_state.murdered_id.to_s] == Role::MERLIN
        game_state.state = State::BAD_FINAL
      else
        game_state.state = State::GOOD_FINAL
      end
    end
    game_state.save
    create_hash(game_state)
  end

  #private

  def create_hash(game_state)
    {
      runtimeType: game_state.state,
      adminId: game_state.admin_id,
      playerCount: game_state.player_count,
      players: game_state.players,
      missions: game_state.missions,
      currentMission: game_state.current_mission,
      leaderId: game_state.leader_id,
      currentVote: game_state.current_vote,
      votesForCandidates: game_state.votes_for_candidates,
      candidates: game_state.candidates,
      votesForResult: game_state.votes_for_result.values.shuffle,
      murderedId: game_state.murdered_id,
    }
  end
end