class CreateAppSettingsAndBreakGlassAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :app_settings, :key, unique: true

    create_table :break_glass_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :clinical_case, null: false, foreign_key: true
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.string :ip_address
      t.timestamps
    end
    add_index :break_glass_accesses, [ :user_id, :clinical_case_id, :expires_at ], name: "idx_break_glass_active_lookup"
  end
end
