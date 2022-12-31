class ChatChannel < ApplicationCable::Channel
  def subscribed
    @player = connection.current_user
    @game = GameState.find(params[:game])
    @chat_stream_name = "chat_#{params[:game]}"
    reject_subscription if @game.nil?

    stream_from @chat_stream_name
  end

  def unsubscribed
    stop_stream_from @chat_stream_name
  end

  def send_message(data)
    ActionCable.server.broadcast(@chat_stream_name, {from:  @player.nickname, message: data["message"]})
  end
end



