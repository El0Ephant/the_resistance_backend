class ProfileController < ApplicationController
  before_action :get_user

  def account_info
    render json: @user, only: [:nickname, :login, :email]
  end

  def stat
    render json: calc_stat
  end

  def matches_history
    per_page = (params[:per_page] || 5).to_i
    page = (params[:page] || 1).to_i
    game_ids = @user.participations.map &:game_id
    games = Game.where(id: game_ids).page(page, per_page)
    result = games.map do |game|
      game.serializable_hash.merge({ role: Participation.find_by(user_id: @user.id, game_id: game.id).role })
    end
    render json: result, except: [:updated_at]
  end

  private

  def get_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
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