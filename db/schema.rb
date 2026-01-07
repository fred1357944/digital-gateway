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

ActiveRecord::Schema[8.1].define(version: 2026_01_07_100003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "max_uses"
    t.bigint "order_id", null: false
    t.datetime "revoked_at"
    t.string "token"
    t.datetime "updated_at", null: false
    t.integer "use_count"
    t.bigint "user_id", null: false
    t.index ["order_id"], name: "index_access_tokens_on_order_id"
    t.index ["token"], name: "index_access_tokens_on_token"
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "ai_conversations", force: :cascade do |t|
    t.text "context_summary"
    t.datetime "created_at", null: false
    t.decimal "estimated_cost_usd", precision: 10, scale: 6, default: "0.0"
    t.string "last_query"
    t.jsonb "last_result", default: {}
    t.jsonb "missing_slots", default: [], null: false
    t.jsonb "recent_messages", default: [], null: false
    t.string "session_id", null: false
    t.jsonb "slots", default: {}, null: false
    t.string "state", default: "gathering", null: false
    t.integer "total_input_tokens", default: 0
    t.integer "total_output_tokens", default: 0
    t.integer "turn_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_ai_conversations_on_created_at"
    t.index ["session_id"], name: "index_ai_conversations_on_session_id"
    t.index ["state"], name: "index_ai_conversations_on_state"
    t.index ["user_id"], name: "index_ai_conversations_on_user_id"
  end

  create_table "ai_credit_transactions", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "ai_conversation_id"
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.jsonb "token_usage", default: {}
    t.bigint "user_id", null: false
    t.index ["action_type"], name: "index_ai_credit_transactions_on_action_type"
    t.index ["ai_conversation_id"], name: "index_ai_credit_transactions_on_ai_conversation_id"
    t.index ["created_at"], name: "index_ai_credit_transactions_on_created_at"
    t.index ["user_id"], name: "index_ai_credit_transactions_on_user_id"
  end

  create_table "ai_feedbacks", force: :cascade do |t|
    t.bigint "ai_conversation_id"
    t.datetime "created_at", null: false
    t.string "feedback_type", null: false
    t.bigint "product_id"
    t.text "query"
    t.text "reason"
    t.text "response_summary"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ai_conversation_id"], name: "index_ai_feedbacks_on_ai_conversation_id"
    t.index ["feedback_type"], name: "index_ai_feedbacks_on_feedback_type"
    t.index ["product_id"], name: "index_ai_feedbacks_on_product_id"
    t.index ["user_id", "created_at"], name: "index_ai_feedbacks_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_ai_feedbacks_on_user_id"
  end

  create_table "mvt_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "details"
    t.bigint "product_id", null: false
    t.decimal "score"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_mvt_reports_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ecpay_trade_no"
    t.string "merchant_trade_no"
    t.bigint "product_id", null: false
    t.integer "status"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["merchant_trade_no"], name: "index_orders_on_merchant_trade_no"
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_scores", force: :cascade do |t|
    t.datetime "calculated_at"
    t.string "calculation_version", default: "1.0"
    t.datetime "created_at", null: false
    t.integer "price_score", default: 50, null: false
    t.bigint "product_id", null: false
    t.integer "quality_score", default: 50, null: false
    t.integer "relevance_score", default: 50, null: false
    t.integer "reputation_score", default: 50, null: false
    t.integer "speed_score", default: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["price_score"], name: "index_product_scores_on_price_score"
    t.index ["product_id"], name: "index_product_scores_on_product_id", unique: true
    t.index ["quality_score"], name: "index_product_scores_on_quality_score"
  end

  create_table "products", force: :cascade do |t|
    t.jsonb "ai_metadata", default: {}, null: false
    t.string "content_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "preview_url"
    t.decimal "price"
    t.bigint "seller_profile_id", null: false
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["ai_metadata"], name: "index_products_on_ai_metadata", using: :gin
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["seller_profile_id"], name: "index_products_on_seller_profile_id"
  end

  create_table "seller_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.integer "status"
    t.string "store_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["discarded_at"], name: "index_seller_profiles_on_discarded_at"
    t.index ["user_id"], name: "index_seller_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "ai_credits", default: 100, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.text "gemini_api_key_ciphertext"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["ai_credits"], name: "index_users_on_ai_credits"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_tokens", "orders"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "ai_conversations", "users"
  add_foreign_key "ai_credit_transactions", "ai_conversations"
  add_foreign_key "ai_credit_transactions", "users"
  add_foreign_key "ai_feedbacks", "ai_conversations"
  add_foreign_key "ai_feedbacks", "products"
  add_foreign_key "ai_feedbacks", "users"
  add_foreign_key "mvt_reports", "products"
  add_foreign_key "orders", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "product_scores", "products"
  add_foreign_key "products", "seller_profiles"
  add_foreign_key "seller_profiles", "users"
end
