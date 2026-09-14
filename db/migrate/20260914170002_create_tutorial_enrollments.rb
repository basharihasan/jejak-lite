class CreateTutorialEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :tutorial_enrollments do |t|
      t.references :user, null: false, foreign_key: true              # mahasiswa
      t.references :tutor, null: true, foreign_key: { to_table: :users }
      t.references :academic_period, null: false, foreign_key: true
      t.string :block_name, null: false      # sistem/blok, mis. "Sistem Kardiovaskular"
      t.string :group_name                   # kelompok tutorial, mis. "Kelompok 3"
      t.date :start_date
      t.date :end_date
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :tutorial_enrollments, [ :user_id, :academic_period_id, :block_name ],
              unique: true, name: "idx_tutorial_enrollments_unique_block"
  end
end
