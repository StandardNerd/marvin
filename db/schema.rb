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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_001532) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "dataset_examples", force: :cascade do |t|
    t.integer "dataset_id", null: false
    t.json "messages"
    t.json "metadata"
    t.boolean "accepted"
    t.json "validation_errors"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_id"], name: "index_dataset_examples_on_dataset_id"
  end

  create_table "datasets", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name"
    t.text "description"
    t.string "format"
    t.string "status", default: "uploaded"
    t.integer "examples_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_datasets_on_project_id"
  end

  create_table "evaluations", force: :cascade do |t|
    t.integer "training_run_id", null: false
    t.string "name"
    t.string "status", default: "pending"
    t.json "metrics"
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_run_id"], name: "index_evaluations_on_training_run_id"
  end

  create_table "model_artifacts", force: :cascade do |t|
    t.integer "training_run_id", null: false
    t.string "name"
    t.string "version"
    t.string "base_model"
    t.text "description"
    t.integer "file_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_run_id"], name: "index_model_artifacts_on_training_run_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.text "description"
    t.string "base_model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "training_metrics", force: :cascade do |t|
    t.integer "training_run_id", null: false
    t.integer "step"
    t.float "epoch"
    t.float "loss"
    t.float "learning_rate"
    t.json "raw_metrics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_run_id"], name: "index_training_metrics_on_training_run_id"
  end

  create_table "training_runs", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "dataset_id", null: false
    t.string "name"
    t.string "base_model"
    t.string "status", default: "pending"
    t.json "configuration"
    t.json "metrics"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_id"], name: "index_training_runs_on_dataset_id"
    t.index ["project_id"], name: "index_training_runs_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dataset_examples", "datasets"
  add_foreign_key "datasets", "projects"
  add_foreign_key "evaluations", "training_runs"
  add_foreign_key "model_artifacts", "training_runs"
  add_foreign_key "projects", "users"
  add_foreign_key "training_metrics", "training_runs"
  add_foreign_key "training_runs", "datasets"
  add_foreign_key "training_runs", "projects"
end
