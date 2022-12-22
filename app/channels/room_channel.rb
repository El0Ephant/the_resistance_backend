class RoomChannel < ApplicationCable::Channel

  def subscribed
    @player_id = connection.current_user["id"]
    @room_id = params[:room_id]
    @room_name = "room_#{@room_id}"
    stream_from @room_name
    @timeout = 2
  end

  def unsubscribed
  end
  # def create_game(data)
  #   ActionCable.server.broadcast(@room_name, GameStateHelper::create_game(@room_id, data["player_count"], data["roles"]))
  # end

  # lobby admin actions
  def hand_over_adminship(data)
    return unless have_admin_permission?(GameStateHelper::State::WAITING)
    ActionCable.server.broadcast(@room_name, GameStateHelper::hand_over_adminship(data["player"]))
  end

  def kick_player(data)
    return unless have_admin_permission?(GameStateHelper::State::WAITING)
    ActionCable.server.broadcast(@room_name, GameStateHelper::free_up_seat(@room_id, data["player"]))
  end

  def start_game
    return unless have_admin_permission?(GameStateHelper::State::WAITING)
    ActionCable.server.broadcast(@room_name, GameStateHelper::start_game(@room_id))
  end

  # other actions
  def take_seat
    return if is_here?(@room_id, @player_id)
    ActionCable.server.broadcast(@room_name,GameStateHelper::take_seat(@room_id, @player_id))
  end

  def free_up_seat
    return unless is_here?(@room_id, @player_id)
    ActionCable.server.broadcast(@room_name, GameStateHelper::free_up_seat(@room_id, @player_id))
  end

  # in-game actions
  def pick_player_for_mission(data)
    return unless have_lobby_leader_permission?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_mission(@room_id, data["player"]))
  end

  def unpick_player_for_mission(data)
    return unless have_lobby_leader_permission?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::unpick_player_for_mission(@room_id, data["player"]))
  end

  def confirm_team
    return unless have_lobby_leader_permission?(GameStateHelper::State::PICK_CANDIDATES)
    ActionCable.server.broadcast(@room_name, GameStateHelper::confirm_team(@room_id))
  end

  def vote_for_candidates(data)
    return unless right_state?(@room_id, GameStateHelper::State::VOTE_FOR_CANDIDATES)
    st = GameStateHelper::vote_for_candidates(@room_id, @player_id, data["choice"])
    ActionCable.server.broadcast(@room_name, st)
    return unless st["state"] == State::VOTE_FOR_CANDIDATES_REVEALED

    sleep(@timeout)
    ActionCable.server.broadcast(@room_name, GameStateHelper::after_vote(@room_id))
  end

  def vote_for_result(data)
    return unless right_state?(@room_id, GameStateHelper::State::VOTE_FOR_RESULT)
    st = GameStateHelper::vote_for_result(@room_id, @player_id, data["result"])
    ActionCable.server.broadcast(@room_name, st)
    return unless st["state"] == State::VOTE_FOR_RESULT_REVEALED

    sleep(@timeout)
    ActionCable.server.broadcast(@room_name, GameStateHelper::end_step(@room_id))
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
    return unless have_permission?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER, GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_murder(@room_id, data["player"]))
  end
  def unpick_player_for_murder(data)
    return unless have_permission?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER, GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::unpick_player_for_murder(@room_id, data["player"]))
  end

  def confirm_murder
    return unless have_permission?(GameStateHelper::State::PICK_PLAYER_FOR_MURDER, GameStateHelper::Role::ASSASSIN)
    ActionCable.server.broadcast(@room_name, GameStateHelper::confirm_murder(@room_id))
  end

  private
  def have_permission?(state, role)
    right_state?(@room_id, state) && right_role?(@room_id, @player_id, role)
  end

  def have_admin_permission?(state)
    right_state?(@room_id, state) && is_admin?(@room_id, @player_id)
  end

  def have_lobby_leader_permission?(state)
    right_state?(@room_id, state) && is_leader?(@room_id, @player_id)
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
  "data": "{\"action\":\"speak\",\"body\":\"hello!\"}"
}

{
  "identifier": "{\"channel\":\"RoomChannel\", \"room_id\":77}",
  "command": "message",
  "data": "{\"action\":\"vote\",\"body\":\"hello!\"}"
}
=end

