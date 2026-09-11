# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :sender, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true
      t.string :title, null: false
      t.text :message
      t.string :notification_type
      t.datetime :read_at
      t.datetime :archived_at

      t.timestamps
    end

    add_index :notifications, %i[recipient_id read_at]
    add_index :notifications, %i[recipient_id archived_at]
  end
end
