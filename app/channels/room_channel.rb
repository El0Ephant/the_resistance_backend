class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_#{params[:room_id]}"
  end

  def unsubscribed

  end

  def choose_player(data)
    # если текущее состояние игры - не сбор команды, то return
    # добавить выделенного игрока
    ActionCable.server.broadcast("room_#{params[:room_id]}", "информация о состоянии")
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
=end





