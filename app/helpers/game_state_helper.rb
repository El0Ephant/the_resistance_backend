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

    UNKNOWN_LOYAL = "unknownLoyal"
    UNKNOWN_EVIL = "unknownEvil"
  end

  module Mission
    REQUIRED2 = 2
    REQUIRED3 = 3
    REQUIRED4 = 4
    REQUIRED5 = 5

    WIN = "Win"
    LOOSE = "Loose"
  end

  def self.connect_player(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.online_players << player_id
    game_state.save
  end

  def self.disconnect_player(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.online_players.delete(player_id)
    game_state.save
    game_state.online_players
  end

  def self.create_game(player_count, roles, creator_id)
    max_id = GameState.max(:_id).nil? ? 0 : GameState.max(:_id)
    game_id = (1..max_id + 1).to_a.find_index { |x| GameState.find(x).nil? } + 1

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
                            [2, 2, 2, 2, 2] # ?????? ????????????????????????
                          end
    game_state.admin_id = creator_id
    game_state.leader_id = -1
    game_state.save
    game_id
  end

  def self.delete_game(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.delete
  end

  def self.is_here?(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.players.include?(player_id)
  end

  def self.is_admin?(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.admin_id == player_id
  end

  def self.is_leader?(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.leader_id == player_id
  end

  def self.right_role?(game_id, player_id, *roles)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    roles.include?(game_state.player_roles[player_id.to_s])
  end

  def self.right_state?(game_id, state)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.state == state
    create_state_hash(game_state)
  end

  def self.start_game(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    return create_state_hash(game_state) unless game_state.player_count == game_state.players.size

    players = game_state.players
    roles = game_state.roles
    game_state.player_roles = players.zip(roles.shuffle).to_h
    game_state.leader_id = game_state.players.sample
    game_state.state = GameStateHelper::State::PICK_CANDIDATES
    game_state.save
    create_state_hash(game_state)
  end

  def self.resend(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    create_state_hash(game_state)
  end

  def self.take_seat(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.players << player_id
    game_state.save
    create_state_hash(game_state)
  end

  def self.free_up_seat(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.players.delete(player_id)
    game_state.admin_id = game_state.players.sample if game_state.admin_id == player_id
    game_state.save
    create_state_hash(game_state)
  end

  def self.hand_over_adminship(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.admin_id = player_id
    game_state.save
    create_state_hash(game_state)
  end

  def self.pick_player_for_mission(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.candidates << player_id
    game_state.save
    create_state_hash(game_state)
  end

  def self.unpick_player_for_mission(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.candidates.delete(player_id)
    game_state.save
    create_state_hash(game_state)
  end

  def self.confirm_team(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    if game_state.missions[game_state.current_mission] == game_state.candidates.size
      if game_state.current_vote == 5
        game_state.current_vote = 1
        game_state.state = State::VOTE_FOR_RESULT
        game_state.save
        return create_state_hash(game_state)
      else
        game_state.state = State::VOTE_FOR_CANDIDATES
      end
    end
    game_state.save
    create_state_hash(game_state)
  end

  def self.vote_for_candidates(game_id, player_id, vote)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    GameState.with_session do |s|
      s.start_transaction
      game_state.votes_for_candidates[player_id.to_s] = vote
      if game_state.votes_for_candidates.size == game_state.player_count
        game_state.state = State::VOTE_FOR_CANDIDATES_REVEALED
      end
      game_state.save
      s.commit_transaction
    end
    create_state_hash(game_state)
  end

  def self.after_vote(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

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
      game_state.state = State::PICK_CANDIDATES
      game_state.leader_id = game_state.players[(game_state.players.index(game_state.leader_id) + 1) % game_state.players.size]
    end
    game_state.save
    create_state_hash(game_state)
  end

  def self.vote_for_result(game_id, player_id, vote)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    GameState.with_session do |s|
      s.start_transaction

      if game_state.candidates.include?(player_id)
        game_state.votes_for_result[player_id.to_s] = vote
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
    create_state_hash(game_state)
  end

  def self.end_step(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    missions = game_state.missions
    tally = missions.tally
    if tally[Mission::WIN] == 3
      game_state.state = State::PICK_PLAYER_FOR_MURDER
      game_state.save
      return create_state_hash(game_state)
    end

    if tally[Mission::LOOSE] == 3
      game_state.state = State::BAD_FINAL
      res = create_state_hash(game_state)
      finish_game(game_state)
      return res
    end

    game_state.current_mission += 1

    game_state.state = State::PICK_CANDIDATES
    game_state.candidates = []
    game_state.votes_for_candidates = {}
    game_state.votes_for_result = {}
    game_state.leader_id = game_state.players[(game_state.players.index(game_state.leader_id) + 1) % game_state.players.size]
    game_state.save
    create_state_hash(game_state)
  end

  def self.pick_player_for_murder(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.murdered_id = player_id
    game_state.save
    create_state_hash(game_state)
  end

  def self.unpick_player_for_murder(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    game_state.murdered_id = nil
    game_state.save
    create_state_hash(game_state)
  end

  def self.confirm_murder(game_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    if game_state.murdered_id != nil
      if game_state.player_roles[game_state.murdered_id.to_s] == Role::MERLIN
        game_state.state = State::BAD_FINAL
      else
        game_state.state = State::GOOD_FINAL
      end
    end
    res = create_state_hash(game_state)
    finish_game(game_state)
    res
  end

  def self.get_roles(game_id, player_id)
    game_state = GameState.find(game_id)
    return if game_state.nil?

    player_id = player_id.to_s

    players = game_state.players.map{ |id| id.to_s }
    res = {}
    players.each do |x|
      res[x] = {Name: User.find(x).nickname}
    end
    return { info: res } if game_state.state == State::WAITING

    if game_state.state == State::BAD_FINAL || game_state.state == State::GOOD_FINAL
      players.each do |x|
        res[x][:Role] = pl_roles[x]
      end
      return { info: res }
    end

    pl_roles = game_state.player_roles
    res[player_id][:Role] = pl_roles[player_id]

    puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    puts player_id
    puts pl_roles
    puts res
    p pl_roles

    case pl_roles[player_id]
    when Role::MERLIN
      pl_roles.each do |key, value|
        if [Role::ASSASSIN, Role::MORGANA, Role::OBERON, Role::EVIL].include? value
          res[key][:Role] = Role::UNKNOWN_EVIL
        end
      end
    when Role::PERCIVAL
      pl_roles.each do |key, value|
        if [Role::MERLIN, Role::MORGANA].include? value
          res[key][:Role] = Role::UNKNOWN_LOYAL
        end
      end
    when Role::ASSASSIN, Role::MORGANA, Role::MORDRED, Role::EVIL
      pl_roles.except(player_id).each do |key, value|
        if [Role::ASSASSIN, Role::MORGANA, Role::MORDRED, Role::OBERON, Role::EVIL].include? value
          res[key][:Role] = Role::UNKNOWN_EVIL
        end
      end
    else
    end
    { info:res }
  end

  #private
  def self.mission_transform(mission)
    case mission
    when "Win"
      true
    when "Loose"
      false
    else
      nil
    end
  end
  def self.finish_game(game_state)
    game = Game.create!({winner: game_state.state == State::GOOD_FINAL ? :good : :evil,
                  murdered_id: game_state.murdered_id,
                  mission_1: mission_transform(game_state.missions[0]),
                  mission_2: mission_transform(game_state.missions[1]),
                  mission_3: mission_transform(game_state.missions[2]),
                  mission_4: mission_transform(game_state.missions[3]),
                  mission_5: mission_transform(game_state.missions[4]),
                  created_at: DateTime.now})
    game_state.player_roles.each do |key, value|
      Participation.create!({user_id: key.to_i, game_id: game.id, role: value.to_sym})
    end
    game_state.delete
  end
  def self.create_state_hash(game_state)
    {
      runtimeType: game_state.state,
      gameId: game_state.id,
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