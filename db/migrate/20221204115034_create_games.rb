class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.integer :winner
      t.references :murdered, foreign_key: { to_table: :users }
      t.boolean :mission_1
      t.boolean :mission_2
      t.boolean :mission_3
      t.boolean :mission_4
      t.boolean :mission_5

      t.timestamps
    end
  end
end
