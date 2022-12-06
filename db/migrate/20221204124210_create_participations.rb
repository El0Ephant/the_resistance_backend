class CreateParticipations < ActiveRecord::Migration[7.0]
  def change
    create_table :participations do |t|
      t.references :user
      t.references :game
      t.integer :role

      t.timestamps
    end
  end
end
