class AddCodeAndLevelToStudyPrograms < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :study_programs, :code, :string
    add_column :study_programs, :level, :string

    # Dua baris tetap dari db/seeds.rb diberi kode mengikuti JEJAK (pssk/pspd).
    safety_assured do
      execute <<~SQL
      UPDATE study_programs SET code = 'pssk', level = 'sarjana' WHERE name = 'Sarjana Kedokteran';
      UPDATE study_programs SET code = 'pspd', level = 'profesi' WHERE name = 'Profesi Dokter';
      SQL
    end

    add_index :study_programs, :code, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :study_programs, :code
    remove_column :study_programs, :level
    remove_column :study_programs, :code
  end
end
