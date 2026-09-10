# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :code, unique: true

    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_roles, %i[user_id role_id], unique: true

    # safety_assured: tabel users masih kosong di migrasi bootstrap ini
    # (baru dibuat migrasi sebelumnya), jadi tidak ada lock produksi nyata
    # yang perlu dihindari strong_migrations di sini.
    safety_assured { add_reference :users, :active_role, foreign_key: { to_table: :roles } }
  end
end
