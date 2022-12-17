module GameStateHelper

  def create_game(id, player_count)
    GameState.create(
      id: id,
      player_count: player_count,
      state: "Waiting",

    )
  end
end

