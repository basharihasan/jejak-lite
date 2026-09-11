# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

{
  "mahasiswa" => "Mahasiswa",
  "dosen"     => "Dosen",
  "admin"     => "Admin"
}.each do |code, name|
  Role.find_or_create_by!(code: code) { |role| role.name = name }
end

# Persis 2 prodi tetap — bukan hierarki Faculty/University (lihat
# IMPLEMENTATION_PLAN.md § Keputusan Arsitektur Kunci).
[ "Sarjana Kedokteran", "Profesi Dokter" ].each do |name|
  StudyProgram.find_or_create_by!(name: name)
end
