#methods

def extract_refs (mwtext)
	# Takes in raw wikitext, returns list of strings of reference tags in hash with type
	refindex = 0
	refendex = 0
	lastindex = 0
	refstrings = Array.new
	while TRUE do
		refindex = mwtext.index("<ref", refendex)
		if refindex == nil
			#norefs += mwtext[lastindex:]
			break
		end
		nextref = mwtext.index("<ref", refindex + 1)
		nextref = !nextref ? -1 : nextref	#Convert nils to -1
		slashref = mwtext.index("/>", refindex)
		slashref = !slashref ? -1 : slashref
		refendex = mwtext.index("</ref>",refindex)
		refendex = !refendex ? -1 : refendex
		if ((nextref < slashref) || (slashref == -1)) && ((nextref < refendex) || (refendex == -1)) && (nextref != -1)
			reftype = 'broken'
			refendex = nextref
		elsif ((slashref < nextref) || (nextref == -1)) && ((slashref < refendex) || (refendex == -1)) && (slashref != -1)
			reftype = 'small'
			refendex = slashref + 2
		elsif ((refendex < nextref) || (nextref == -1)) && ((refendex < slashref) || (slashref == -1)) && (refendex != -1)
			reftype = 'normal'
			refendex += 6
		else
			#lolwtf
			puts("Break in the refstring crawling")
			break
		end
		refstrings << {type: reftype, content: mwtext[refindex,refendex-refindex]}
    	lastindex = refendex
	end
	return refstrings
end

def get_wikidata (pageid)
	# grabs data from Wikipedia API
	uri = URI('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvlimit=1&rvprop=ids|timestamp|user|userid|comment|tags|size|content&pageids='+pageid.to_s)
	wikiapidata = Net::HTTP.get_response(uri)
	wikijsondata = JSON.parse(wikiapidata.body)
	wikijsondata["query"]["pages"][pageid.to_s]["revisions"][0].merge!({"pageid" => pageid.to_s})
end
