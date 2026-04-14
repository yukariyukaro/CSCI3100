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

ActiveRecord::Schema[7.2].define(version: 2026_04_14_201525) do
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

  create_table "audit_events", force: :cascade do |t|
    t.integer "community_id", null: false
    t.integer "user_id"
    t.string "action", null: false
    t.string "auditable_type"
    t.bigint "auditable_id"
    t.json "metadata", default: {}, null: false
    t.string "request_id"
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["community_id"], name: "index_audit_events_on_community_id"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "communities", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "max_active_products_per_user", default: 50, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_communities_on_abbreviation", unique: true
    t.index ["name"], name: "index_communities_on_name", unique: true
    t.index ["slug"], name: "index_communities_on_slug", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "buyer_id", null: false
    t.integer "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "community_id", null: false
    t.index ["buyer_id"], name: "index_conversations_on_buyer_id"
    t.index ["community_id"], name: "index_conversations_on_community_id"
    t.index ["product_id", "buyer_id"], name: "index_conversations_on_product_id_and_buyer_id", unique: true
    t.index ["product_id"], name: "index_conversations_on_product_id"
    t.index ["seller_id"], name: "index_conversations_on_seller_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.integer "sender_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "payment_webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "event_id", null: false
    t.integer "payment_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_payment_webhook_events_on_payment_id"
    t.index ["provider", "event_id"], name: "index_payment_webhook_events_on_provider_and_event_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.integer "transaction_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.string "provider", null: false
    t.string "provider_reference"
    t.string "callback_token"
    t.text "error_details"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_reference"], name: "index_payments_on_provider_and_provider_reference", unique: true, where: "provider_reference IS NOT NULL"
    t.index ["resolved_by_id"], name: "index_payments_on_resolved_by_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.decimal "price", default: "0.0", null: false
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ai_summary"
    t.string "ai_summary_status", default: "pending"
    t.datetime "ai_summary_requested_at"
    t.integer "seller_id", null: false
    t.integer "sale_status", default: 0, null: false
    t.string "ai_model"
    t.integer "community_id", null: false
    t.text "ai_last_question"
    t.index ["community_id", "sale_status", "created_at"], name: "index_products_on_community_status_created"
    t.index ["community_id"], name: "index_products_on_community_id"
    t.index ["seller_id", "created_at"], name: "index_products_on_seller_id_and_created_at"
    t.index ["seller_id"], name: "index_products_on_seller_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "buyer_id", null: false
    t.integer "seller_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "community_id", null: false
    t.index ["buyer_id", "created_at"], name: "index_transactions_on_buyer_id_and_created_at"
    t.index ["buyer_id"], name: "index_transactions_on_buyer_id"
    t.index ["community_id"], name: "index_transactions_on_community_id"
    t.index ["product_id"], name: "idx_only_one_active_transaction_per_product", unique: true, where: "status = 1"
    t.index ["product_id"], name: "index_transactions_on_product_id"
    t.index ["seller_id", "created_at"], name: "index_transactions_on_seller_id_and_created_at"
    t.index ["seller_id"], name: "index_transactions_on_seller_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.integer "community_id", null: false
    t.index ["community_id"], name: "index_users_on_community_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_events", "communities"
  add_foreign_key "audit_events", "users"
  add_foreign_key "conversations", "communities"
  add_foreign_key "conversations", "products"
  add_foreign_key "conversations", "users", column: "buyer_id"
  add_foreign_key "conversations", "users", column: "seller_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "payment_webhook_events", "payments"
  add_foreign_key "payments", "transactions"
  add_foreign_key "payments", "users", column: "resolved_by_id"
  add_foreign_key "products", "communities"
  add_foreign_key "products", "users", column: "seller_id"
  add_foreign_key "transactions", "communities"
  add_foreign_key "transactions", "products"
  add_foreign_key "transactions", "users", column: "buyer_id"
  add_foreign_key "transactions", "users", column: "seller_id"
  add_foreign_key "users", "communities"
end
