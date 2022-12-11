class ChangePasswordColumnName < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :password_digest, :encrypted_password
  end
end
