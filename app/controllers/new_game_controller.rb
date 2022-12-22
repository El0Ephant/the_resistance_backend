class NewGameController < MembersController
  include GameStateHelper
  def new_game
    game_id = create_game params[:roles].size, params[:roles]
    render json:{
      gameId: game_id
    }
  end
end