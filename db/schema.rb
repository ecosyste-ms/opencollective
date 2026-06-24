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

ActiveRecord::Schema[8.1].define(version: 2026_06_24_140201) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "advisories", force: :cascade do |t|
    t.float "blast_radius"
    t.string "classification"
    t.datetime "created_at", null: false
    t.float "cvss_score"
    t.string "cvss_vector"
    t.text "description"
    t.string "identifiers", default: [], array: true
    t.string "origin"
    t.jsonb "packages", default: []
    t.integer "project_id"
    t.datetime "published_at"
    t.string "references", default: [], array: true
    t.string "repository_url"
    t.string "severity"
    t.string "source_kind"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "uuid"
    t.datetime "withdrawn_at"
    t.index ["project_id"], name: "index_advisories_on_project_id"
  end

  create_table "collectives", force: :cascade do |t|
    t.string "account_type"
    t.boolean "archived"
    t.float "balance"
    t.datetime "collective_created_at"
    t.datetime "collective_updated_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "description"
    t.string "github"
    t.string "host"
    t.datetime "last_project_activity_at"
    t.datetime "last_synced_at"
    t.string "name"
    t.boolean "no_funding"
    t.boolean "no_license"
    t.json "owner"
    t.integer "projects_count"
    t.string "repository_url"
    t.string "slug"
    t.json "social_links"
    t.string "tags", default: [], array: true
    t.float "total_donations"
    t.integer "transactions_count"
    t.string "twitter"
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.string "website"
    t.index ["account_type"], name: "index_collectives_on_account_type"
    t.index ["host"], name: "index_collectives_on_host"
    t.index ["slug"], name: "index_collectives_on_slug", unique: true
  end

  create_table "commits", force: :cascade do |t|
    t.integer "additions"
    t.string "author"
    t.string "committer"
    t.datetime "created_at", null: false
    t.integer "deletions"
    t.integer "files_changed"
    t.boolean "merge"
    t.string "message"
    t.integer "project_id", null: false
    t.string "sha"
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
    t.index ["project_id", "timestamp"], name: "index_commits_on_project_id_and_timestamp"
  end

  create_table "issues", force: :cascade do |t|
    t.string "assignees"
    t.string "author_association"
    t.string "body"
    t.datetime "closed_at"
    t.string "closed_by"
    t.integer "comments_count"
    t.datetime "created_at", null: false
    t.json "dependency_metadata"
    t.string "html_url"
    t.string "labels", default: [], array: true
    t.boolean "locked"
    t.datetime "merged_at"
    t.string "node_id"
    t.integer "number"
    t.integer "project_id"
    t.boolean "pull_request"
    t.string "state"
    t.string "state_reason"
    t.integer "time_to_close"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "user"
    t.string "uuid"
    t.index ["project_id", "pull_request", "closed_at"], name: "index_issues_on_project_id_and_pull_request_and_closed_at"
    t.index ["project_id", "pull_request", "created_at"], name: "index_issues_on_project_id_and_pull_request_and_created_at"
    t.index ["project_id", "pull_request", "user"], name: "index_issues_on_project_id_and_pull_request_and_user"
  end

  create_table "packages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ecosystem"
    t.json "metadata"
    t.string "name"
    t.integer "project_id", null: false
    t.string "purl"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_packages_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "collective_id"
    t.json "commit_stats"
    t.datetime "created_at", null: false
    t.integer "issues_count", default: 0
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.integer "packages_count"
    t.text "readme"
    t.json "repository"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["collective_id"], name: "index_projects_on_collective_id"
    t.index ["url"], name: "index_projects_on_url", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "html_url"
    t.string "kind"
    t.string "name"
    t.integer "project_id", null: false
    t.datetime "published_at"
    t.string "sha"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_tags_on_project_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "account"
    t.float "amount"
    t.integer "collective_id"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "description"
    t.float "net_amount"
    t.string "transaction_expense_type"
    t.string "transaction_kind"
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["collective_id", "transaction_type", "created_at"], name: "idx_on_collective_id_transaction_type_created_at_e56e46ac84"
    t.index ["collective_id", "updated_at"], name: "index_transactions_on_collective_id_and_updated_at"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end
end
