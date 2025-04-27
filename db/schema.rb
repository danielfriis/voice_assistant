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

ActiveRecord::Schema[8.0].define(version: 2025_04_27_153730) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "calendars", force: :cascade do |t|
    t.bigint "identity_id", null: false
    t.string "provider_id"
    t.boolean "visible", default: true
    t.string "title"
    t.string "description"
    t.string "background_color"
    t.string "foreground_color"
    t.string "time_zone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_calendars_on_identity_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "calendar_id", null: false
    t.string "provider_id"
    t.string "title"
    t.text "description"
    t.string "status"
    t.date "start_date"
    t.time "start_time"
    t.date "end_date"
    t.time "end_time"
    t.string "html_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_id"], name: "index_events_on_calendar_id"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "email"
    t.string "name"
    t.json "raw_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "memories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_memories_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_notes_on_project_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "description"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.bigint "user_id", null: false
    t.bigint "todo_id"
    t.date "due_date"
    t.time "due_time"
    t.integer "priority", default: 0
    t.integer "time_estimate"
    t.integer "position"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.index ["project_id"], name: "index_todos_on_project_id"
    t.index ["todo_id"], name: "index_todos_on_todo_id"
    t.index ["user_id"], name: "index_todos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "time_zone"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "calendars", "identities"
  add_foreign_key "events", "calendars"
  add_foreign_key "identities", "users"
  add_foreign_key "memories", "users"
  add_foreign_key "notes", "projects"
  add_foreign_key "notes", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "todos", "projects"
  add_foreign_key "todos", "todos"
  add_foreign_key "todos", "users"
end
