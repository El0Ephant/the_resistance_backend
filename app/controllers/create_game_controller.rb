class CreateGameController < MembersController
  def create_game
    game_id = GameStateHelper::create_game params[:roles].size, params[:roles], @user.id
    render json:{
      gameId: game_id
    }
  end
end