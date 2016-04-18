# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160418041942) do

  create_table "articles", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.text     "url",         limit: 65535
    t.string   "source",      limit: 255
    t.date     "date"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "description", limit: 65535
  end

  create_table "articles_companies", force: :cascade do |t|
    t.integer "article_id", limit: 4
    t.integer "company_id", limit: 4
  end

  create_table "brackets", force: :cascade do |t|
    t.integer  "bracket_code",  limit: 4
    t.float    "opening_price", limit: 24
    t.float    "high_price",    limit: 24
    t.float    "low_price",     limit: 24
    t.float    "closing_price", limit: 24
    t.date     "date"
    t.integer  "turnover",      limit: 8
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "brackets", ["bracket_code", "date"], name: "index_brackets_on_bracket_code_and_date", unique: true, using: :btree

  create_table "commodities", force: :cascade do |t|
    t.date     "date"
    t.integer  "commodity_code", limit: 4
    t.float    "opening_price",  limit: 24
    t.float    "high_price",     limit: 24
    t.float    "low_price",      limit: 24
    t.float    "closing_price",  limit: 24
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "commodities", ["commodity_code", "date"], name: "index_commodities_on_commodity_code_and_date", unique: true, using: :btree

  create_table "companies", force: :cascade do |t|
    t.integer  "company_code",      limit: 4
    t.string   "name",              limit: 255
    t.text     "description",       limit: 65535
    t.integer  "accounting_period", limit: 4
    t.integer  "trading_unit",      limit: 4
    t.integer  "industry_code",     limit: 4
    t.date     "established_date"
    t.date     "listed_date"
    t.integer  "market_code",       limit: 4
    t.integer  "country_code",      limit: 4
    t.string   "url",               limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "companies", ["company_code"], name: "index_companies_on_company_code", unique: true, using: :btree

  create_table "companies_tags", id: false, force: :cascade do |t|
    t.integer "company_id", limit: 4
    t.integer "tag_id",     limit: 4
  end

  create_table "credit_deals", force: :cascade do |t|
    t.date     "date"
    t.integer  "selling_balance", limit: 4
    t.integer  "debt_balance",    limit: 4
    t.float    "margin_ratio",    limit: 24
    t.integer  "company_id",      limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "credit_deals", ["company_id", "date"], name: "index_credit_deals_on_company_id_and_date", unique: true, using: :btree

  create_table "foreign_exchanges", force: :cascade do |t|
    t.date     "date"
    t.float    "opening_price", limit: 24
    t.float    "high_price",    limit: 24
    t.float    "low_price",     limit: 24
    t.float    "closing_price", limit: 24
    t.integer  "currency_code", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "foreign_exchanges", ["currency_code", "date"], name: "index_foreign_exchanges_on_currency_code_and_date", unique: true, using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "tag_type",   limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tags_trends", force: :cascade do |t|
    t.integer "trend_id", limit: 4
    t.integer "tag_id",   limit: 4
  end

  create_table "transactions", force: :cascade do |t|
    t.date     "date"
    t.integer  "high_price",    limit: 4
    t.integer  "low_price",     limit: 4
    t.integer  "opening_price", limit: 4
    t.integer  "closing_price", limit: 4
    t.integer  "turnover",      limit: 4
    t.float    "vwap",          limit: 24
    t.integer  "company_id",    limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "transactions", ["company_id", "date"], name: "index_transactions_on_company_id_and_date", unique: true, using: :btree

  create_table "trends", force: :cascade do |t|
    t.date     "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "trends", ["date"], name: "index_trends_on_date", unique: true, using: :btree

end
