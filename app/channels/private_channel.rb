class PrivateChannel < ApplicationCable::Channel

  def subscribed
    @player_id = connection.current_user["id"]
    @room_id = params[:room_id]
    stream_from "player_#{@player_id}"
  end

  def unsubscribed
  end

  def get_roles
    ActionCable.server.broadcast("player_#{@player_id}", GameStateHelper::get_roles(@room_id, @player_id))
  end

end


