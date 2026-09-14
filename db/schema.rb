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

ActiveRecord::Schema[8.1].define(version: 2026_09_15_010001) do
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

  create_table "activity_log_competency_tags", force: :cascade do |t|
    t.bigint "activity_log_id", null: false
    t.bigint "competency_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_log_id", "competency_item_id"], name: "index_activity_log_competency_tags_uniq", unique: true
    t.index ["activity_log_id"], name: "index_activity_log_competency_tags_on_activity_log_id"
    t.index ["competency_item_id"], name: "index_activity_log_competency_tags_on_competency_item_id"
  end

  create_table "activity_logs", force: :cascade do |t|
    t.date "activity_date", null: false
    t.string "activity_type"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "delivery_mode"
    t.text "description"
    t.string "location"
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

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.jsonb "value", default: {}, null: false
    t.index ["key"], name: "index_app_settings_on_key", unique: true
    t.index ["updated_by_id"], name: "index_app_settings_on_updated_by_id"
  end

  create_table "assessment_blueprint_mappings", force: :cascade do |t|
    t.bigint "assessment_blueprint_id", null: false
    t.bigint "competency_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 5, scale: 2, null: false
    t.index ["assessment_blueprint_id", "competency_item_id"], name: "index_blueprint_mappings_uniq", unique: true
    t.index ["assessment_blueprint_id"], name: "index_assessment_blueprint_mappings_on_assessment_blueprint_id"
    t.index ["competency_item_id"], name: "index_assessment_blueprint_mappings_on_competency_item_id"
  end

  create_table "assessment_blueprints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "learning_outcomes", default: [], null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "assessment_events", force: :cascade do |t|
    t.bigint "academic_period_id", null: false
    t.boolean "allow_multiple_attempts", default: false, null: false
    t.bigint "assessment_form_template_id"
    t.string "assessment_type", null: false
    t.string "block_name"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.date "exam_date"
    t.decimal "max_score", precision: 6, scale: 2, default: "100.0", null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.bigint "study_program_id"
    t.datetime "submission_close_at"
    t.datetime "updated_at", null: false
    t.index ["academic_period_id", "assessment_type"], name: "idx_on_academic_period_id_assessment_type_60ee6849bc"
    t.index ["academic_period_id"], name: "index_assessment_events_on_academic_period_id"
    t.index ["assessment_form_template_id"], name: "index_assessment_events_on_assessment_form_template_id"
    t.index ["created_by_id"], name: "index_assessment_events_on_created_by_id"
    t.index ["study_program_id"], name: "index_assessment_events_on_study_program_id"
  end

  create_table "assessment_form_answers", force: :cascade do |t|
    t.bigint "assessment_form_field_id", null: false
    t.bigint "assessment_form_submission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["assessment_form_field_id"], name: "index_assessment_form_answers_on_assessment_form_field_id"
    t.index ["assessment_form_submission_id"], name: "index_assessment_form_answers_on_assessment_form_submission_id"
  end

  create_table "assessment_form_fields", force: :cascade do |t|
    t.bigint "assessment_form_template_id", null: false
    t.datetime "created_at", null: false
    t.string "field_type", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_form_template_id"], name: "index_assessment_form_fields_on_assessment_form_template_id"
  end

  create_table "assessment_form_submissions", force: :cascade do |t|
    t.bigint "assessment_form_template_id", null: false
    t.datetime "created_at", null: false
    t.bigint "respondent_id", null: false
    t.string "subject_label"
    t.bigint "subject_user_id"
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_form_template_id"], name: "idx_on_assessment_form_template_id_27a2546b02"
    t.index ["respondent_id"], name: "index_assessment_form_submissions_on_respondent_id"
    t.index ["subject_user_id"], name: "index_assessment_form_submissions_on_subject_user_id"
  end

  create_table "assessment_form_templates", force: :cascade do |t|
    t.boolean "anonymous", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.boolean "requires_subject_user", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_assessment_form_templates_on_created_by_id"
  end

  create_table "assessment_instances", force: :cascade do |t|
    t.bigint "assessment_event_id", null: false
    t.bigint "assessment_form_submission_id"
    t.integer "attempt_number", default: 1, null: false
    t.bigint "clinical_case_id"
    t.datetime "created_at", null: false
    t.bigint "examiner_id"
    t.text "feedback_improve"
    t.text "feedback_keep"
    t.decimal "max_score", precision: 6, scale: 2, default: "100.0", null: false
    t.datetime "scheduled_at"
    t.decimal "score", precision: 6, scale: 2
    t.datetime "scored_at"
    t.text "self_evaluation"
    t.string "source", default: "manual", null: false
    t.string "status", default: "registered", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["assessment_event_id", "student_id", "attempt_number"], name: "idx_assessment_instances_unique_attempt", unique: true
    t.index ["assessment_event_id"], name: "index_assessment_instances_on_assessment_event_id"
    t.index ["assessment_form_submission_id"], name: "index_assessment_instances_on_assessment_form_submission_id"
    t.index ["clinical_case_id"], name: "index_assessment_instances_on_clinical_case_id"
    t.index ["examiner_id"], name: "index_assessment_instances_on_examiner_id"
    t.index ["student_id", "status"], name: "index_assessment_instances_on_student_id_and_status"
    t.index ["student_id"], name: "index_assessment_instances_on_student_id"
  end

  create_table "assessment_mappings", force: :cascade do |t|
    t.bigint "assessment_event_id", null: false
    t.datetime "created_at", null: false
    t.bigint "learning_unit_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["assessment_event_id"], name: "index_assessment_mappings_on_assessment_event_id"
    t.index ["learning_unit_id", "assessment_event_id"], name: "idx_assessment_mappings_unique", unique: true
    t.index ["learning_unit_id"], name: "index_assessment_mappings_on_learning_unit_id"
  end

  create_table "break_glass_accesses", force: :cascade do |t|
    t.bigint "clinical_case_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.text "reason", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["clinical_case_id"], name: "index_break_glass_accesses_on_clinical_case_id"
    t.index ["user_id", "clinical_case_id", "expires_at"], name: "idx_break_glass_active_lookup"
    t.index ["user_id"], name: "index_break_glass_accesses_on_user_id"
  end

  create_table "case_verification_comments", force: :cascade do |t|
    t.string "action", null: false
    t.text "body"
    t.bigint "clinical_case_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["clinical_case_id"], name: "index_case_verification_comments_on_clinical_case_id"
    t.index ["user_id"], name: "index_case_verification_comments_on_user_id"
  end

  create_table "clinical_cases", force: :cascade do |t|
    t.text "anamnesis"
    t.string "case_complexity"
    t.date "case_date", null: false
    t.string "chief_complaint", null: false
    t.string "clinical_setting"
    t.datetime "created_at", null: false
    t.text "diagnosis"
    t.string "entrustment_level"
    t.text "family_history"
    t.text "general_condition"
    t.string "icd10_code"
    t.text "learning_points"
    t.text "management"
    t.text "patient_address"
    t.integer "patient_age"
    t.string "patient_age_group"
    t.text "patient_birth_date"
    t.string "patient_gender"
    t.text "patient_medical_record_number"
    t.text "patient_name"
    t.string "patient_occupation"
    t.text "patient_phone"
    t.text "physical_examination"
    t.boolean "recommend_remediation", default: false, null: false
    t.string "skdi_level"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.datetime "verified_at"
    t.bigint "verified_by_id"
    t.jsonb "vital_signs", default: {}, null: false
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

  create_table "competency_frameworks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "competency_items", force: :cascade do |t|
    t.bigint "competency_framework_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["competency_framework_id"], name: "index_competency_items_on_competency_framework_id"
    t.index ["parent_id"], name: "index_competency_items_on_parent_id"
  end

  create_table "competency_milestones", force: :cascade do |t|
    t.bigint "academic_period_id", null: false
    t.bigint "competency_item_id", null: false
    t.datetime "created_at", null: false
    t.integer "expected_score", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_period_id"], name: "index_competency_milestones_on_academic_period_id"
    t.index ["competency_item_id", "academic_period_id"], name: "index_competency_milestones_uniq", unique: true
    t.index ["competency_item_id"], name: "index_competency_milestones_on_competency_item_id"
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

  create_table "diagnosis_definitions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "icd10_code"
    t.string "name", null: false
    t.string "skdi_level"
    t.string "system_group"
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "idx_diagnosis_definitions_lower_name", unique: true
    t.index ["icd10_code"], name: "index_diagnosis_definitions_on_icd10_code"
  end

  create_table "dops_evaluations", force: :cascade do |t|
    t.string "case_complexity"
    t.bigint "clinical_rotation_id", null: false
    t.string "clinical_setting"
    t.datetime "created_at", null: false
    t.date "evaluated_at", null: false
    t.bigint "evaluator_id", null: false
    t.integer "feedback_minutes"
    t.integer "observation_minutes"
    t.text "overall_feedback"
    t.string "patient_age_group"
    t.string "procedure_name", null: false
    t.jsonb "scores", default: {}, null: false
    t.string "status", default: "submitted", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.string "video_recording_url"
    t.index ["clinical_rotation_id"], name: "index_dops_evaluations_on_clinical_rotation_id"
    t.index ["evaluator_id"], name: "index_dops_evaluations_on_evaluator_id"
    t.index ["student_id", "evaluated_at"], name: "index_dops_evaluations_on_student_id_and_evaluated_at"
    t.index ["student_id"], name: "index_dops_evaluations_on_student_id"
  end

  create_table "entrustment_decisions", force: :cascade do |t|
    t.bigint "clinical_case_id"
    t.bigint "competency_item_id", null: false
    t.datetime "created_at", null: false
    t.bigint "decided_by_id", null: false
    t.text "justification", null: false
    t.integer "level", null: false
    t.bigint "student_id", null: false
    t.datetime "superseded_at"
    t.bigint "superseded_by_id"
    t.datetime "updated_at", null: false
    t.index ["clinical_case_id"], name: "index_entrustment_decisions_on_clinical_case_id"
    t.index ["competency_item_id"], name: "index_entrustment_decisions_on_competency_item_id"
    t.index ["decided_by_id"], name: "index_entrustment_decisions_on_decided_by_id"
    t.index ["student_id", "competency_item_id", "superseded_at"], name: "idx_entrustment_current_lookup"
    t.index ["student_id"], name: "index_entrustment_decisions_on_student_id"
    t.index ["superseded_by_id"], name: "index_entrustment_decisions_on_superseded_by_id"
  end

  create_table "evaluation_schedules", force: :cascade do |t|
    t.bigint "clinical_rotation_id"
    t.datetime "created_at", null: false
    t.bigint "evaluator_id"
    t.string "kind", null: false
    t.text "notes"
    t.datetime "scheduled_at", null: false
    t.string "status", default: "planned", null: false
    t.bigint "student_id", null: false
    t.string "topic"
    t.datetime "updated_at", null: false
    t.index ["clinical_rotation_id"], name: "index_evaluation_schedules_on_clinical_rotation_id"
    t.index ["evaluator_id", "status"], name: "index_evaluation_schedules_on_evaluator_id_and_status"
    t.index ["evaluator_id"], name: "index_evaluation_schedules_on_evaluator_id"
    t.index ["student_id", "scheduled_at"], name: "index_evaluation_schedules_on_student_id_and_scheduled_at"
    t.index ["student_id"], name: "index_evaluation_schedules_on_student_id"
  end

  create_table "exam_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "imported_by_id", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "row_count", default: 0, null: false
    t.integer "unmatched_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["imported_by_id"], name: "index_exam_imports_on_imported_by_id"
  end

  create_table "exam_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "exam_date", null: false
    t.bigint "exam_import_id", null: false
    t.decimal "max_score", precision: 6, scale: 2, default: "100.0", null: false
    t.decimal "score", precision: 6, scale: 2, null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_import_id"], name: "index_exam_scores_on_exam_import_id"
    t.index ["student_id", "exam_date"], name: "index_exam_scores_on_student_id_and_exam_date"
    t.index ["student_id"], name: "index_exam_scores_on_student_id"
  end

  create_table "examiner_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "examiner_id", null: false
    t.text "feedback"
    t.bigint "final_project_id", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.date "session_date", null: false
    t.datetime "updated_at", null: false
    t.index ["examiner_id"], name: "index_examiner_scores_on_examiner_id"
    t.index ["final_project_id"], name: "index_examiner_scores_on_final_project_id"
  end

  create_table "final_project_milestones", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "final_project_id", null: false
    t.date "target_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["final_project_id"], name: "index_final_project_milestones_on_final_project_id"
  end

  create_table "final_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "status", default: "proposal", null: false
    t.bigint "student_id", null: false
    t.bigint "supervisor_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_final_projects_on_student_id"
    t.index ["supervisor_id"], name: "index_final_projects_on_supervisor_id"
  end

  create_table "learning_units", force: :cascade do |t|
    t.bigint "academic_period_id"
    t.bigint "assessment_blueprint_id"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "credits"
    t.text "description"
    t.string "name", null: false
    t.bigint "study_program_id", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_period_id"], name: "index_learning_units_on_academic_period_id"
    t.index ["assessment_blueprint_id"], name: "index_learning_units_on_assessment_blueprint_id"
    t.index ["study_program_id", "academic_period_id", "name"], name: "idx_learning_units_unique", unique: true
    t.index ["study_program_id"], name: "index_learning_units_on_study_program_id"
  end

  create_table "logbook_case_targets", force: :cascade do |t|
    t.bigint "academic_period_id"
    t.datetime "created_at", null: false
    t.string "facility_type", null: false
    t.text "notes"
    t.bigint "study_program_id", null: false
    t.integer "target_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["academic_period_id"], name: "index_logbook_case_targets_on_academic_period_id"
    t.index ["study_program_id", "academic_period_id", "facility_type"], name: "idx_logbook_case_targets_unique", unique: true
    t.index ["study_program_id"], name: "index_logbook_case_targets_on_study_program_id"
  end

  create_table "mini_cex_evaluations", force: :cascade do |t|
    t.string "case_complexity"
    t.string "case_description", null: false
    t.bigint "clinical_rotation_id", null: false
    t.string "clinical_setting"
    t.datetime "created_at", null: false
    t.date "evaluated_at", null: false
    t.bigint "evaluator_id", null: false
    t.integer "feedback_minutes"
    t.string "global_rating"
    t.integer "observation_minutes"
    t.text "overall_feedback"
    t.string "patient_age_group"
    t.jsonb "scores", default: {}, null: false
    t.string "status", default: "submitted", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.string "video_recording_url"
    t.index ["clinical_rotation_id"], name: "index_mini_cex_evaluations_on_clinical_rotation_id"
    t.index ["evaluator_id"], name: "index_mini_cex_evaluations_on_evaluator_id"
    t.index ["student_id", "evaluated_at"], name: "index_mini_cex_evaluations_on_student_id_and_evaluated_at"
    t.index ["student_id"], name: "index_mini_cex_evaluations_on_student_id"
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

  create_table "patient_consents", force: :cascade do |t|
    t.bigint "clinical_case_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "items", default: {}, null: false
    t.datetime "revoked_at"
    t.datetime "signed_at"
    t.string "signer_name"
    t.string "signer_relation"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["clinical_case_id"], name: "index_patient_consents_on_clinical_case_id", unique: true
    t.index ["token"], name: "index_patient_consents_on_token", unique: true
  end

  create_table "reflection_entries", force: :cascade do |t|
    t.bigint "activity_log_id"
    t.bigint "clinical_case_id"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.date "entry_date", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["activity_log_id"], name: "index_reflection_entries_on_activity_log_id"
    t.index ["clinical_case_id"], name: "index_reflection_entries_on_clinical_case_id"
    t.index ["user_id", "entry_date"], name: "index_reflection_entries_on_user_id_and_entry_date"
    t.index ["user_id"], name: "index_reflection_entries_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "skill_definitions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "skdi_level"
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "idx_skill_definitions_lower_name", unique: true
  end

  create_table "study_programs", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "level"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_study_programs_on_code", unique: true
    t.index ["name"], name: "index_study_programs_on_name", unique: true
  end

  create_table "tutorial_enrollments", force: :cascade do |t|
    t.bigint "academic_period_id", null: false
    t.boolean "active", default: true, null: false
    t.string "block_name", null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "group_name"
    t.date "start_date"
    t.bigint "tutor_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["academic_period_id"], name: "index_tutorial_enrollments_on_academic_period_id"
    t.index ["tutor_id"], name: "index_tutorial_enrollments_on_tutor_id"
    t.index ["user_id", "academic_period_id", "block_name"], name: "idx_tutorial_enrollments_unique_block", unique: true
    t.index ["user_id"], name: "index_tutorial_enrollments_on_user_id"
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
    t.text "address"
    t.date "birth_date"
    t.string "birth_place"
    t.string "calendar_feed_token"
    t.integer "cohort_year"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "font_size_preference", default: "normal", null: false
    t.string "full_name", default: "", null: false
    t.string "gender"
    t.string "identifier_number"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "locale_preference", default: "id", null: false
    t.string "phone"
    t.string "position"
    t.string "profession_category"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "specialization"
    t.bigint "study_program_id"
    t.string "theme_preference", default: "system", null: false
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "work_unit"
    t.index ["active_role_id"], name: "index_users_on_active_role_id"
    t.index ["calendar_feed_token"], name: "index_users_on_calendar_feed_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["identifier_number"], name: "index_users_on_identifier_number"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["study_program_id"], name: "index_users_on_study_program_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_log_competency_tags", "activity_logs"
  add_foreign_key "activity_log_competency_tags", "competency_items"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "app_settings", "users", column: "updated_by_id"
  add_foreign_key "assessment_blueprint_mappings", "assessment_blueprints"
  add_foreign_key "assessment_blueprint_mappings", "competency_items"
  add_foreign_key "assessment_events", "academic_periods"
  add_foreign_key "assessment_events", "assessment_form_templates"
  add_foreign_key "assessment_events", "study_programs"
  add_foreign_key "assessment_events", "users", column: "created_by_id"
  add_foreign_key "assessment_form_answers", "assessment_form_fields"
  add_foreign_key "assessment_form_answers", "assessment_form_submissions"
  add_foreign_key "assessment_form_fields", "assessment_form_templates"
  add_foreign_key "assessment_form_submissions", "assessment_form_templates"
  add_foreign_key "assessment_form_submissions", "users", column: "respondent_id"
  add_foreign_key "assessment_form_submissions", "users", column: "subject_user_id"
  add_foreign_key "assessment_form_templates", "users", column: "created_by_id"
  add_foreign_key "assessment_instances", "assessment_events"
  add_foreign_key "assessment_instances", "assessment_form_submissions"
  add_foreign_key "assessment_instances", "clinical_cases"
  add_foreign_key "assessment_instances", "users", column: "examiner_id"
  add_foreign_key "assessment_instances", "users", column: "student_id"
  add_foreign_key "assessment_mappings", "assessment_events"
  add_foreign_key "assessment_mappings", "learning_units"
  add_foreign_key "break_glass_accesses", "clinical_cases"
  add_foreign_key "break_glass_accesses", "users"
  add_foreign_key "case_verification_comments", "clinical_cases"
  add_foreign_key "case_verification_comments", "users"
  add_foreign_key "clinical_cases", "users"
  add_foreign_key "clinical_cases", "users", column: "verified_by_id"
  add_foreign_key "clinical_rotations", "academic_periods"
  add_foreign_key "clinical_rotations", "users"
  add_foreign_key "clinical_rotations", "users", column: "preceptor_id"
  add_foreign_key "competency_items", "competency_frameworks"
  add_foreign_key "competency_items", "competency_items", column: "parent_id"
  add_foreign_key "competency_milestones", "academic_periods"
  add_foreign_key "competency_milestones", "competency_items"
  add_foreign_key "device_push_tokens", "users"
  add_foreign_key "dops_evaluations", "clinical_rotations"
  add_foreign_key "dops_evaluations", "users", column: "evaluator_id"
  add_foreign_key "dops_evaluations", "users", column: "student_id"
  add_foreign_key "entrustment_decisions", "clinical_cases"
  add_foreign_key "entrustment_decisions", "competency_items"
  add_foreign_key "entrustment_decisions", "entrustment_decisions", column: "superseded_by_id"
  add_foreign_key "entrustment_decisions", "users", column: "decided_by_id"
  add_foreign_key "entrustment_decisions", "users", column: "student_id"
  add_foreign_key "evaluation_schedules", "clinical_rotations"
  add_foreign_key "evaluation_schedules", "users", column: "evaluator_id"
  add_foreign_key "evaluation_schedules", "users", column: "student_id"
  add_foreign_key "exam_imports", "users", column: "imported_by_id"
  add_foreign_key "exam_scores", "exam_imports"
  add_foreign_key "exam_scores", "users", column: "student_id"
  add_foreign_key "examiner_scores", "final_projects"
  add_foreign_key "examiner_scores", "users", column: "examiner_id"
  add_foreign_key "final_project_milestones", "final_projects"
  add_foreign_key "final_projects", "users", column: "student_id"
  add_foreign_key "final_projects", "users", column: "supervisor_id"
  add_foreign_key "learning_units", "academic_periods"
  add_foreign_key "learning_units", "assessment_blueprints"
  add_foreign_key "learning_units", "study_programs"
  add_foreign_key "logbook_case_targets", "academic_periods"
  add_foreign_key "logbook_case_targets", "study_programs"
  add_foreign_key "mini_cex_evaluations", "clinical_rotations"
  add_foreign_key "mini_cex_evaluations", "users", column: "evaluator_id"
  add_foreign_key "mini_cex_evaluations", "users", column: "student_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "notifications", "users", column: "sender_id"
  add_foreign_key "patient_consents", "clinical_cases"
  add_foreign_key "reflection_entries", "activity_logs"
  add_foreign_key "reflection_entries", "clinical_cases"
  add_foreign_key "reflection_entries", "users"
  add_foreign_key "tutorial_enrollments", "academic_periods"
  add_foreign_key "tutorial_enrollments", "users"
  add_foreign_key "tutorial_enrollments", "users", column: "tutor_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "roles", column: "active_role_id"
  add_foreign_key "users", "study_programs"
end
