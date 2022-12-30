module GameStateHelper
  module State
    WAITING = "waiting"
    PICK_CANDIDATES = "pickCandidates"
    VOTE_FOR_CANDIDATES = "voteForCandidates"
    VOTE_FOR_RESULT = "voteForResult"

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

  def self.connect_player(game, player_id)
    game.online_players << player_id
    game.save
  end

  def self.disconnect_player(game, player_id)
    game.online_players.delete(player_id)
    game.save
    game.online_players
  end

  def self.create_game(player_count, roles, creator_id)
    max_id = GameState.max(:_id).nil? ? 0 : GameState.max(:_id)
    game_id = (1..max_id + 1).to_a.find_index { |x| GameState.find(x).nil? } + 1

    game = GameState.create(id: game_id, player_count: player_count, roles: roles)
    game.missions, game.need_fails = case player_count
                          when 5
                            [[2, 3, 2, 3, 3], [1, 1, 1, 1, 1]]
                          when 6
                            [[2, 3, 4, 3, 4], [1, 1, 1, 1, 1]]
                          when 7
                            [[2, 3, 3, 4, 4], [1, 1, 1, 2, 1]]
                          when 8
                            [[3, 4, 4, 5, 5], [1, 1, 1, 2, 1]]
                          when 9
                            [[3, 4, 4, 5, 5], [1, 1, 1, 2, 1]]
                          when 10
                            [[3, 4, 4, 5, 5], [1, 1, 1, 2, 1]]
                          else
                            [[2, 2, 2, 2, 2], [1, 1, 1, 1, 1]] # для тестирования
                                     end
    game.admin_id = creator_id
    game.leader_id = -1
    game.save

    RemoveRoomJob.set(wait: 1.day).perform_later(game)
    game_id
  end

  def self.start_game(game)
    return game.to_h unless game.player_count == game.players.size

    players = game.players
    roles = game.roles
    game.player_roles = players.zip(roles.shuffle).to_h
    game.leader_id = game.players.sample
    game.state = GameStateHelper::State::PICK_CANDIDATES
    game.save
    game.to_h

  end

  def self.take_seat(game, player_id)
    game.players << player_id
    game.save
    game.to_h
  end

  def self.free_up_seat(game, player_id)
    game.players.delete(player_id)
    game.admin_id = game.players.sample if game.admin_id == player_id
    game.save
    game.to_h
  end

  def self.hand_over_adminship(game, player_id)
    game.admin_id = player_id
    game.save
    game.to_h
  end

  def self.pick_player_for_mission(game, player_id)
    game.candidates << player_id
    game.save
    game.to_h
  end

  def self.unpick_player_for_mission(game, player_id)
    game.candidates.delete(player_id)
    game.save
    game.to_h
  end

  def self.confirm_team(game)
    if game.missions[game.current_mission] == game.candidates.size
      if game.current_vote == 5
        game.current_vote = 1
        game.state = State::VOTE_FOR_RESULT
        game.save
        return game.to_h
      else
        game.state = State::VOTE_FOR_CANDIDATES
      end
    end
    game.save
    game.to_h
  end

  def self.vote_for_candidates(game, player_id, vote)
    GameState.with_session do |s|
      s.start_transaction
      game.votes_for_candidates[player_id.to_s] = vote
      if game.votes_for_candidates.size == game.player_count
        result = 0
        game.votes_for_candidates.values.each do |value|
          result += value ? 1 : -1
        end

        if result.positive?
          game.current_vote = 1
          game.state = State::VOTE_FOR_RESULT
        else
          game.current_vote += 1
          game.candidates = []
          game.state = State::PICK_CANDIDATES
          game.leader_id = game.players[(game.players.index(game.leader_id) + 1) % game.players.size]
        end
      end

      game.save
      s.commit_transaction
    end
    game.to_h
  end
  def self.reset_votes_for_candidates(game)
    game.votes_for_candidates = {}
    game.save
    game.to_h
  end

  def self.vote_for_result(game, player_id, vote)
     GameState.with_session do |s|
      s.start_transaction

      if game.candidates.include?(player_id)
        game.votes_for_result[player_id.to_s] = vote
      end

      if game.votes_for_result.size == game.candidates.size
        game.missions[game.current_mission] =
          game.votes_for_result.values.count(false) < game.need_fails[game.current_mission] ? Mission::WIN : Mission::LOOSE

        missions_tally = game.missions.tally

        if missions_tally[Mission::WIN] == 3
          game.state = State::PICK_PLAYER_FOR_MURDER
          game.save
          return game.to_h
        end

        if missions_tally[Mission::LOOSE] == 3
          game.state = State::BAD_FINAL
          res = game.to_h
          finish_game(game)
          return res
        end

        game.current_mission += 1

        game.state = State::PICK_CANDIDATES
        game.candidates = []
        game.votes_for_candidates = {}
        game.leader_id = game.players[(game.players.index(game.leader_id) + 1) % game.players.size]
      end

      game.save
      s.commit_transaction
    end
    game.to_h
  end
  def self.pick_player_for_murder(game, player_id)
    game.murdered_id = player_id
    game.save
    game.to_h
  end

  def self.confirm_murder(game)
    if game.murdered_id != nil
      if game.player_roles[game.murdered_id.to_s] == Role::MERLIN
        game.state = State::BAD_FINAL
      else
        game.state = State::GOOD_FINAL
      end
    end
    res = game.to_h
    finish_game(game)
    res
  end

  def self.get_roles(game, player_id)
    player_id = player_id.to_s

    players = game.players.map{ |id| id.to_s }
    res = {}
    players.each do |x|
      res[x] = {Name: User.find(x).nickname}
    end
    return { info: res } if game.state == State::WAITING

    if game.state == State::BAD_FINAL || game.state == State::GOOD_FINAL
      players.each do |x|
        res[x][:Role] = pl_roles[x]
      end
      return { info: res }
    end

    pl_roles = game.player_roles
    res[player_id][:Role] = pl_roles[player_id]

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
  def self.finish_game(game)
    game_id = Game.create!({winner: game.state == State::GOOD_FINAL ? :good : :evil,
                  murdered_id: game.murdered_id,
                  mission_1: mission_transform(game.missions[0]),
                  mission_2: mission_transform(game.missions[1]),
                  mission_3: mission_transform(game.missions[2]),
                  mission_4: mission_transform(game.missions[3]),
                  mission_5: mission_transform(game.missions[4]),
                  created_at: DateTime.now}).id
    game.player_roles.each do |key, value|
      Participation.create!({user_id: key.to_i, game_id: game_id, role: value.to_sym})
    end
    game.delete
  end
end