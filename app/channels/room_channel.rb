class RoomChannel < ApplicationCable::Channel
  def subscribed
    @user = connection.current_user
    @room_name = "room_#{params[:room_id]}"
    stream_from @room_name
  end

  def unsubscribed
  end
  #@todo добавить реальные state вместо заглушек
  # lobby leader actions
  def hand_over_leadership(data)
    return unless have_permission?(state: "заполнение комнаты", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::hand_over_leadership(data["player"]))
  end

  def kick_player(data)
    return unless have_permission?(state: "заполнение комнаты", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::kick_player(data["player"]))
  end

  def start_game
    return unless have_permission?(state: "заполнение комнаты", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::start_game)
  end

  # other actions
  def take_seat
    return unless have_permission?(state: "заполнение комнаты", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::take_seat(@user))
  end

  def free_up_seat
    return unless have_permission?(state: "заполнение комнаты", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::free_up_seat(@user))
  end

  def pick_player_for_mission(data)
    return unless have_permission?(state: "выбор людей для похода", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::pick_player_for_mission(data["player"]))
  end

  def confirm_team
    return unless have_permission?(state: "выбор людей для похода", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::confirm_team)
  end

  def vote_for_mission(data)
    return unless have_permission?(state: "голосование за поход", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::vote_for_mission(from: @user, choice: data["choice"]))
  end

  def vote_for_result(data)
    return unless have_permission?(state: "поход", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::select_result(from: @user, choice: data["result"]))
  end

  def pick_player_for_lol(data) # the Lady of the Lake
    return unless have_permission?(state: "выбор людей для вскрытия роли игроку с токеном Леди Лейк", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::pick_player_for_lol(data["player"]))
  end

  def confirm_lol
    return unless have_permission?(state: "выбор людей для вскрытия роли игроку с токеном Леди Лейк", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::confirm_lol)
  end

  def pick_player_for_murder(data)
    return unless have_permission?(state: "Убийство", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::pick_player_for_kill(data["player"]))
  end

  def confirm_murder
    return unless have_permission?(state: "Убийство", user: @user)
    ActionCable.server.broadcast(@room_name, Helper::confirm_kill)
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

