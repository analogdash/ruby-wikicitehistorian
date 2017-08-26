require 'net/http'
require 'json'
require_relative 'methods'

pageid = 142721 #MARCOS


mwtext = get_wikidata(pageid)
reftest = extract_refs(mwtext["*"])


wikijsondata["query"]["pages"][pageid.to_s]["revisions"].each do |revision|
	File.open("wtxt/"+revision["revid"].to_s+".txt", "w") do |aFile|
		aFile.write(JSON.generate(revision))
	end
end

while ! wikijsondata.keys.include?("batchcomplete") do
    conti = wikijsondata["continue"]["continue"]
    rvconti = wikijsondata["continue"]["rvcontinue"]
    uri = URI('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvlimit=50&rvprop=ids|timestamp|user|userid|comment|tags|size|content&pageids='+pageid.to_s+"&continue="+conti+"&rvcontinue="+rvconti)
    wikiapidata = Net::HTTP.get_response(uri)
    wikijsondata = JSON.parse(wikiapidata.body)
    wikijsondata["query"]["pages"][pageid.to_s]["revisions"].each do |revision|
		File.open("wtxt/"+revision["revid"].to_s+".txt", "w") do |aFile|
			aFile.write(JSON.generate(revision))
		end
	end
end

mwtext = wikijsondata["query"]["pages"][pageid.to_s]["revisions"][0]["*"]
