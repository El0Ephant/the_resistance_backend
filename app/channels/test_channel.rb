class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "test_channel"
  end

  def unsubscribed

  end

  def speak(data)
    ActionCable.server.broadcast("test_channel", data["body"])
  end
end

=begin
ws://localhost:3000/cable

{
  "command":"subscribe",
  "identifier":"{\"channel\":\"TestChannel\"}"
}

{
  "identifier": "{\"channel\":\"TestChannel\"}",
  "command": "message",
  "data": "{\"action\":\"speak\",\"body\":\"hello!\"}"
}
=end





