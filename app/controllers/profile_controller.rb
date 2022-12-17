class ProfileController < MembersController
  before_action :find_user, except: [:my_account_info, :set_nickname]

  def set_nickname
    if params[:nickname].nil?
      render json: {
        message: 'Something went wrong'
      }, status: 422
      return
    end
    @user.nickname = params[:nickname]
    @user.save
    render json: @user, only: [:id, :nickname, :login, :email]
  end
  def my_account_info
    render json: @user, only: [:id, :nickname, :login, :email]
  end

  def account_info
    render json: @user, only: [:id, :nickname, :login]
  end

  def stat
    render json: calc_stat
  end

  def games_history
    per_page = (params[:per_page] || 5).to_i
    page = (params[:page] || 1).to_i
    game_ids = @user.participations.map &:game_id
    games = Game.where(id: game_ids).page(page, per_page)
    result = games.map {|game| calc_game_history game }
    render json: result, except: [:updated_at]
  end

  private

  def find_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def calc_game_history(game)
    participation = Participation.find_by(user_id: @user.id, game_id: game.id)
    {
      id: game.id,
      role: participation.role,
      result: game.evil_won? == participation.evil? ? 'win':'loss',
      mission1: game.mission_1,
      mission2: game.mission_2,
      mission3: game.mission_3,
      mission4: game.mission_4,
      mission5: game.mission_5,
      date: game.created_at.to_s[/\d\d\d\d-\d\d-\d\d/],
      time: game.created_at.to_s[/\d\d:\d\d/]
    }
  end

  def calc_stat
    @participations = @user.participations
    @games = Game.find @participations.map &:game_id
    {
      matches: @participations.count,
      victories: victories,
      withMurder: @games.count { |game| !game.murdered_id.nil? },
      evil: @participations.count { |p| p.evil?},
      evilVictories: evil_victories,
      merlinMurders: merlin_murders,
      goodness: @participations.count { |p| p.good? },
      goodnessVictories: goodness_victories,
      merlinImitations: merlin_imitations,
    }
  end

  def victories
    @participations.count do |p|
      p.evil? == @games.find{ |game| game.id == p.game_id }.evil_won?
    end
  end

  def evil_victories
    @participations.count do |p|
      p.evil? && @games.find{ |game| game.id == p.game_id }.evil_won?
    end
  end

  def merlin_murders
    @participations.count do |p|
      game = @games.find{ |game| game.id == p.game_id }
      p.evil? && game.evil_won? && !game.murdered_id.nil?
    end
  end

  def goodness_victories
    @participations.count do |p|
      p.good? && @games.find{ |game| game.id == p.game_id }.good_won?
    end
  end

  def merlin_imitations
    @participations.count do |p|
      game = @games.find{ |game| game.id == p.game_id }
      p.good? && game.good_won? && game.murdered_id == @user.id
    end
  end
end