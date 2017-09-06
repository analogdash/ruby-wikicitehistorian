pageid = 142721 #MARCOS

uri = URI('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvlimit=50&rvprop=ids|timestamp|user|userid|comment|tags|size|content&pageids='+pageid.to_s)
wikiapidata = Net::HTTP.get_response(uri)
wikijsondata = JSON.parse(wikiapidata.body)

wikijsondata["query"]["pages"][pageid.to_s]["revisions"].each do |revision|
	rev = ArticleRevision.new
	rev.revision_id = revision["revid"]
	rev.previous_revision_id = revision["parentid"]
	rev.article_id = pageid
	rev.comment = revision["comment"]
	rev.wikipedia_editor = revision["user"]
	rev.wikipedia_editor_id = revision["userid"]
	rev.size = revision["size"]
	rev.revision_timestamp = DateTime.parse(revision["timestamp"])
	rev.content = revision["*"]
	rev.save
end

while ! wikijsondata.keys.include?("batchcomplete") do
    conti = wikijsondata["continue"]["continue"]
    rvconti = wikijsondata["continue"]["rvcontinue"]
    uri = URI('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvlimit=50&rvprop=ids|timestamp|user|userid|comment|tags|size|content&pageids='+pageid.to_s+"&continue="+conti+"&rvcontinue="+rvconti)
	puts "Grabbing data"
    wikiapidata = Net::HTTP.get_response(uri)
    puts "Got mah data"
    wikijsondata = JSON.parse(wikiapidata.body)
	wikijsondata["query"]["pages"][pageid.to_s]["revisions"].each do |revision|
		rev = ArticleRevision.new
		rev.revision_id = revision["revid"]
		rev.previous_revision_id = revision["parentid"]
		rev.article_id = pageid
		rev.comment = revision["comment"]
		rev.wikipedia_editor = revision["user"]
		rev.wikipedia_editor_id = revision["userid"]
		rev.size = revision["size"]
		rev.revision_timestamp = DateTime.parse(revision["timestamp"])
		rev.content = revision["*"]
		rev.save
	end
end
