# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_11_003912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "academic_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.date "activity_date", null: false
    t.string "activity_type"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "participant_count"
    t.string "patient_code"
    t.text "reflection"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category"], name: "index_activity_logs_on_category"
    t.index ["user_id", "activity_date"], name: "index_activity_logs_on_user_id_and_activity_date"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "clinical_cases", force: :cascade do |t|
    t.date "case_date", null: false
    t.string "chief_complaint", null: false
    t.datetime "created_at", null: false
    t.text "diagnosis"
    t.text "learning_points"
    t.text "management"
    t.string "patient_age_group"
    t.string "patient_gender"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "verification_comment"
    t.datetime "verified_at"
    t.bigint "verified_by_id"
    t.index ["status"], name: "index_clinical_cases_on_status"
    t.index ["user_id", "status"], name: "index_clinical_cases_on_user_id_and_status"
    t.index ["user_id"], name: "index_clinical_cases_on_user_id"
    t.index ["verified_by_id"], name: "index_clinical_cases_on_verified_by_id"
  end

  create_table "clinical_rotations", force: :cascade do |t|
    t.bigint "academic_period_id", null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "institution_name"
    t.bigint "preceptor_id"
    t.date "start_date", null: false
    t.string "station_name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["academic_period_id"], name: "index_clinical_rotations_on_academic_period_id"
    t.index ["preceptor_id"], name: "index_clinical_rotations_on_preceptor_id"
    t.index ["user_id", "start_date"], name: "index_clinical_rotations_on_user_id_and_start_date"
    t.index ["user_id"], name: "index_clinical_rotations_on_user_id"
  end

  create_table "device_push_tokens", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["endpoint"], name: "index_device_push_tokens_on_endpoint", unique: true
    t.index ["user_id"], name: "index_device_push_tokens_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.text "message"
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type"
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "archived_at"], name: "index_notifications_on_recipient_id_and_archived_at"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["sender_id"], name: "index_notifications_on_sender_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "study_programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_study_programs_on_name", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "active_role_id"
    t.string "calendar_feed_token"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.bigint "study_program_id"
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["active_role_id"], name: "index_users_on_active_role_id"
    t.index ["calendar_feed_token"], name: "index_users_on_calendar_feed_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["study_program_id"], name: "index_users_on_study_program_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "clinical_cases", "users"
  add_foreign_key "clinical_cases", "users", column: "verified_by_id"
  add_foreign_key "clinical_rotations", "academic_periods"
  add_foreign_key "clinical_rotations", "users"
  add_foreign_key "clinical_rotations", "users", column: "preceptor_id"
  add_foreign_key "device_push_tokens", "users"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "notifications", "users", column: "sender_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "roles", column: "active_role_id"
  add_foreign_key "users", "study_programs"
end
