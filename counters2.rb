$t1 = Time.now
ArticleRevision.find_each do |r|
  lol = ReferenceItem.where(parent_revision_id: r.revision_id)
  r.items_normal = lol.where(reference_type: "normal").count
  r.items_short = lol.where(reference_type: "short").count
  r.items_broken = lol.where(reference_type: "broken").count
  r.items = r.items_normal + r.items_short + r.items_broken
  r.save
end
$t2 = Time.now
