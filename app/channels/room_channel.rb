class RoomChannel < ApplicationCable::Channel
  @timeout = 2
  def subscribed
    @player_id = connection.current_user["id"]
    @room_name = "room_#{params[:room_id]}"
    @private_stream_name = "private_stream_#{@player_id}"
    @game = GameState.find(params[:room_id])
    stream_from @room_name
    return unless game_exists?

    stream_from @private_stream_name
    ActionCable.server.broadcast(@private_stream_name, @game.to_h)
    GameStateHelper::connect_player(@game, @player_id)
  end

  def unsubscribed
    stop_stream_from @private_stream_name
    @game.delete if GameStateHelper::disconnect_player(@game, @player_id).empty? && right_state?(GameStateHelper::State::WAITING)
    stop_stream_from @room_name if @game.nil?
  end

  # lobby admin actions
  def hand_over_adminship(data)
    return unless game_exists?
    return unless is_admin? && right_state?(GameStateHelper::State::WAITING)

    ActionCable.server.broadcast(@room_name, GameStateHelper::hand_over_adminship(@game, data["player"]))
  end

  def kick_player(data)
    return unless game_exists?
    return unless is_admin? && right_state?(GameStateHelper::State::WAITING)

    ActionCable.server.broadcast(@room_name, GameStateHelper::free_up_seat(@game, data["player"]))
  end

  def start_game
    return unless game_exists?
    return unless is_admin? && right_state?(GameStateHelper::State::WAITING)

    ActionCable.server.broadcast(@room_name, GameStateHelper::start_game(@game))
  end

  # other actions
  def take_seat
    return unless game_exists?

    ActionCable.server.broadcast(@room_name, GameStateHelper::take_seat(@game, @player_id))
  end

  def free_up_seat
    return unless game_exists? && is_here?

    ActionCable.server.broadcast(@room_name, GameStateHelper::free_up_seat(@game, @player_id))
  end

  # in-game actions
  def pick_player_for_mission(data)
    return unless game_exists?

    return unless is_leader? && right_state?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_mission(@game, data["player"]))
  end

  def unpick_player_for_mission(data)
    return unless game_exists?

    return unless is_leader? && right_state?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::unpick_player_for_mission(@game, data["player"]))
  end

  def confirm_team
    return unless game_exists?

    return unless is_leader? && right_state?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::confirm_team(@game))
  end

  def vote_for_candidates(data)
    return unless game_exists?

    return unless is_here? && right_state?(GameStateHelper::State::VOTE_FOR_CANDIDATES)
    game_hash = GameStateHelper::vote_for_candidates(@game, @player_id, data["choice"])
    unless right_state?(GameStateHelper::State::VOTE_FOR_CANDIDATES)
      ActionCable.server.broadcast(@room_name, game_hash)
      sleep @timeout
      ActionCable.server.broadcast(@room_name, GameStateHelper::reset_votes_for_candidates(@game))
    end
  end

  def vote_for_result(data)
    return unless game_exists?

    return unless is_here? && right_state?(GameStateHelper::State::VOTE_FOR_RESULT)
    game_hash = GameStateHelper::vote_for_result(@game, @player_id, data["choice"])
    ActionCable.server.broadcast(@room_name, game_hash) unless right_state?(GameStateHelper::State::VOTE_FOR_RESULT)
  end

  # def pick_player_for_lol(data) # the Lady of the Lake
  #   return unless have_permission?(state: "выбор людей для вскрытия роли игроку с токеном Леди Лейк", user: @user)
  #   ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_lol(data["player"]))
  # end
  #
  # def confirm_lol
  #   return unless have_permission?(state: "выбор людей для вскрытия роли игроку с токеном Леди Лейк", user: @user)
  #   ActionCable.server.broadcast(@room_name, GameStateHelper::confirm_lol)
  # end

  def pick_player_for_murder(data)
    return unless game_exists?

    return unless is_here? && right_state?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER) && right_role?(GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_murder(@game, data["player"]))
  end
  def unpick_player_for_murder(data)
    return unless game_exists?

    return unless is_here? && right_state?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER) && right_role?(GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::unpick_player_for_murder(@game, data["player"]))
  end

  def confirm_murder
    return unless game_exists?

    return unless is_here? && right_state?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER) && right_role?(GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::confirm_murder(@game))
  end

  private

  def is_admin?
    @game.admin_id == @player_id
  end

  def is_leader?
    @game.leader_id == @player_id
  end

  def right_state?(state)
    @game.state == state
  end

  def right_role?(*roles)
    roles.include?(@game.player_roles[@player_id.to_s])
  end

  def self.is_here?
    @game.players.include?(@player_id)
  end


  def game_exists?
    if @game.nil?
      ActionCable.server.broadcast(@room_name, {runtimeType: "gameDoesNotExists"})
      stop_stream_from @room_name
      return false
    end
    true
  end
end

=begin
ws://localhost:3000/cable

{
  "command": "subscribe",
  "identifier": "{\"channel\":\"RoomChannel\", \"room_id\":77}"
}

{
  "identifier": "{\"channel\":\"RoomChannel\", \"room_id\":77}",
  "command": "message",
  "data": "{\"action\":\"test\",\"body\":\"hello!\"}"
}

=end

