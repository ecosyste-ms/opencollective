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

ActiveRecord::Schema[7.1].define(version: 2024_01_22_154429) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collective_projects", force: :cascade do |t|
    t.integer "collective_id"
    t.integer "project_id"
    t.string "name"
    t.string "description"
    t.string "category"
    t.string "sub_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collective_id"], name: "index_collective_projects_on_collective_id"
    t.index ["project_id"], name: "index_collective_projects_on_project_id"
  end

  create_table "collectives", force: :cascade do |t|
    t.string "uuid"
    t.string "slug"
    t.string "name"
    t.string "description"
    t.string "tags", default: [], array: true
    t.string "website"
    t.string "github"
    t.string "twitter"
    t.string "repository_url"
    t.json "social_links"
    t.string "currency"
    t.integer "projects_count"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "transactions_count"
    t.float "balance"
    t.string "kind"
    t.json "owner"
    t.datetime "last_project_activity_at"
    t.boolean "archived"
    t.index ["slug"], name: "index_collectives_on_slug", unique: true
  end

  create_table "issues", force: :cascade do |t|
    t.integer "project_id"
    t.string "uuid"
    t.string "node_id"
    t.integer "number"
    t.string "state"
    t.string "title"
    t.string "body"
    t.string "user"
    t.string "assignees"
    t.boolean "locked"
    t.integer "comments_count"
    t.boolean "pull_request"
    t.datetime "closed_at"
    t.string "closed_by"
    t.string "author_association"
    t.string "state_reason"
    t.integer "time_to_close"
    t.datetime "merged_at"
    t.json "dependency_metadata"
    t.string "html_url"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "labels", default: [], array: true
    t.index ["project_id"], name: "index_issues_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "url"
    t.json "repository"
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "issues_count", default: 0
    t.json "packages", default: []
    t.index ["url"], name: "index_projects_on_url", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "collective_id"
    t.string "uuid"
    t.float "amount"
    t.float "net_amount"
    t.string "transaction_type"
    t.string "currency"
    t.string "account"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_kind"
    t.string "transaction_expense_type"
    t.index ["collective_id"], name: "index_transactions_on_collective_id"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

end
