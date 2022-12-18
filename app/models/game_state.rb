class GameState
  include Mongoid::Document
  field :_id, type: Integer

  field :admin_id, type: Integer
  field :player_count, type: Integer
  field :state, type: String, default: GameStateHelper::State::WAITING

  field :roles, type: Array, default: []
  field :players, type: Array, default: []

  field :player_roles, type: Hash, default: {}
  field :missions, type: Array, default: []
  field :current_mission, type: Integer, default: 0

  field :leader_id, type: Integer
  field :current_vote, type: Integer, default: 1
  field :votes_for_candidates, type: Hash, default: {}
  field :candidates, type: Array, default: []

  field :votes_for_result, type: Array, default: []
  field :murdered_id, type: Integer

end

