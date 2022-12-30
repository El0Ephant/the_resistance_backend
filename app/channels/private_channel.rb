class PrivateChannel < ApplicationCable::Channel

  def subscribed
    @player_id = connection.current_user["id"]
    @game = GameState.find(params[:game])
    return unless game_exists?

    stream_from "player_#{@player_id}"
  end

  def unsubscribed
    stop_stream_from "player_#{@player_id}"
  end

  def get_roles
    ActionCable.server.broadcast("player_#{@player_id}", GameStateHelper::get_roles(@game, @player_id))
  end

end


