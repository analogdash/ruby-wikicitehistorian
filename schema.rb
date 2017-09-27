ActiveRecord::Schema.define(version: 20170926091425) do

  create_table "articles", force: :cascade do |t|
    t.integer  "pageid"
    t.string   "title"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "lastrevid"
    t.integer  "fullurl"
    t.integer  "revisions_count"
  end

  create_table "reference_instances", force: :cascade do |t|
    t.integer  "revid"
    t.integer  "position"
    t.text     "wikitext"
    t.string   "reftype"
    t.string   "refname"
    t.string   "content"
    t.string   "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "size"
  end

  create_table "revisions", force: :cascade do |t|
    t.integer  "pageid"
    t.integer  "revid"
    t.integer  "parentid"
    t.string   "user"
    t.integer  "userid"
    t.integer  "size"
    t.datetime "timestamp"
    t.string   "comment"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "instances_count"
    t.integer  "instances_normal_count"
    t.integer  "instances_broken_count"
  end

end
