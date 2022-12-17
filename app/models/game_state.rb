class GameState
  include Mongoid::Document
  field :_id, type: Integer

  field :admin_id, type: Integer
  field :player_count, type: Integer
  field :state, type: String
  field :missions, type: Array, default: []

  field :leader_id, type: Integer
  field :current_vote, type: Integer
  field :votes_for_candidates, type: Hash, default: {}
  field :candidates, type: Array, default: []

  field :votes_for_mission, type: Array, default: []

  field :roles, type: Hash, default: {}

end

