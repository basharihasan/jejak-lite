# frozen_string_literal: true

class CreateDevicePushTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_push_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false

      t.timestamps
    end

    add_index :device_push_tokens, :endpoint, unique: true
  end
end
