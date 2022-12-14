class RoomChannel < ApplicationCable::Channel

  def subscribed
    @player_id = connection.current_user["id"]
    @room_id = params[:room_id]
    @room_name = "room_#{@room_id}"
    stream_from @room_name
    @timeout = 2
    GameStateHelper::connect_player(@room_id, @player_id)
  end

  def unsubscribed
    return unless GameStateHelper::disconnect_player(@room_id, @player_id).empty?

    stop_stream_from @room_name
    GameStateHelper::delete_game(@room_id)
  end

  # lobby admin actions
  def hand_over_adminship(data)
    return unless have_admin_permission?(GameStateHelper::State::WAITING)
    ActionCable.server.broadcast(@room_name, GameStateHelper::hand_over_adminship(@room_id, data["player"]))
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
    if GameStateHelper::is_here?(@room_id, @player_id)
      ActionCable.server.broadcast(@room_name, GameStateHelper::resend(@room_id))
    else
      ActionCable.server.broadcast(@room_name, GameStateHelper::take_seat(@room_id, @player_id))
    end
  end

  def free_up_seat
    return unless GameStateHelper::is_here?(@room_id, @player_id)
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
    return unless GameStateHelper::right_state?(@room_id, GameStateHelper::State::VOTE_FOR_CANDIDATES)
    st = GameStateHelper::vote_for_candidates(@room_id, @player_id, data["choice"])
    #ActionCable.server.broadcast(@room_name, st)
    return unless st[:runtimeType] == GameStateHelper::State::VOTE_FOR_CANDIDATES_REVEALED
    #sleep(@timeout)
    ActionCable.server.broadcast(@room_name, GameStateHelper::after_vote(@room_id))
  end

  def vote_for_result(data)
    return unless GameStateHelper::right_state?(@room_id, GameStateHelper::State::VOTE_FOR_RESULT)
    st = GameStateHelper::vote_for_result(@room_id, @player_id, data["choice"])
    return unless st[:runtimeType] == GameStateHelper::State::VOTE_FOR_RESULT_REVEALED
    #ActionCable.server.broadcast(@room_name, st)
    #sleep(@timeout)
    ActionCable.server.broadcast(@room_name, GameStateHelper::end_step(@room_id))
  end

  # def pick_player_for_lol(data) # the Lady of the Lake
  #   return unless have_permission?(state: "?????????? ?????????? ?????? ???????????????? ???????? ???????????? ?? ?????????????? ???????? ????????", user: @user)
  #   ActionCable.server.broadcast(@room_name, GameStateHelper::pick_player_for_lol(data["player"]))
  # end
  #
  # def confirm_lol
  #   return unless have_permission?(state: "?????????? ?????????? ?????? ???????????????? ???????? ???????????? ?? ?????????????? ???????? ????????", user: @user)
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
    GameStateHelper::right_state?(@room_id, state) && GameStateHelper::right_role?(@room_id, @player_id, role)
  end

  def have_admin_permission?(state)
    GameStateHelper::right_state?(@room_id, state) && GameStateHelper::is_admin?(@room_id, @player_id)
  end

  def have_lobby_leader_permission?(state)
    GameStateHelper::right_state?(@room_id, state) && GameStateHelper::is_leader?(@room_id, @player_id)
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

