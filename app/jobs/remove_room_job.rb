class RemoveRoomJob < ApplicationJob
  queue_as :rrj

  def perform(game)
    game.delete
  end
end
