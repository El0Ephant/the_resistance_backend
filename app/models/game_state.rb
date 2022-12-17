class GameState
  include Mongoid::Document
  field :_id, type: Integer

  field :state, type: String
  field :player_amount, type: Integer
  field :missions, type: Array, default: []

  field :leader_id, type: Integer
  field :current_vote, type: Integer
  field :votes_for_candidates, type: Hash
  field :candidates, type: Array, default: []

  field :votes_for_mission, type: Array, default: []

  field :roles, type: Hash

end

