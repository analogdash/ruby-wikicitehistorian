#code to update Revisions and parse them too.
def save_revision_info (article,revision)
  rev = Revision.new
  rev.pageid = article.pageid
  rev.revid = revision["revid"]
  rev.parentid = revision["parentid"]
  rev.comment = revision["comment"]
  rev.user = revision["user"]
  rev.userid = revision["userid"]
  rev.size = revision["size"]
  rev.instances_count = 0
  rev.instances_normal_count = 0
  rev.instances_broken_count = 0
  rev.timestamp = DateTime.parse(revision["timestamp"])

  mwtext = revision["*"]
  refindex = 0
  refendex = 0
  position = 1
  while true do
    refindex = mwtext.index("<ref", refendex)
    if refindex == nil
      break
    end
    nextbrack = mwtext.index(/<[^!]/, refindex + 1)
    nextbrack = !nextbrack ? -1 : nextbrack #Convert nils to -1
    slashref = mwtext.index("/>", refindex)
    slashref = !slashref ? -1 : slashref
    refendex = mwtext.index("</ref>",refindex)
    refendex = !refendex ? -1 : refendex
    
    if ((nextbrack < slashref) || (slashref == -1)) && (nextbrack != -1)
      if nextbrack == refendex
        reftype = 'normal'
        refendex += 6
        rev.instances_normal_count += 1
      else
        reftype = 'broken'
        refendex = nextbrack
        rev.instances_broken_count += 1
      end
    elsif ((slashref < nextbrack) || (nextbrack == -1)) && ((slashref < refendex) || (refendex == -1)) && (slashref != -1)
      #NOTE THAT THIS is also triggered by <references/> make sure to catch it.
      reftype = 'short'
      refendex = slashref + 2
      next #we're skipping short references for now
    end

    refstring = ReferenceInstance.new
    refstring.revid = rev.revid
    refstring.reftype = reftype
    refstring.wikitext = mwtext[refindex,refendex-refindex]
    refstring.size = refendex-refindex
    refstring.position = position

    doc = Nokogiri::HTML(refstring.wikitext)
    tag = doc.css("ref")[0]
    unless tag == nil
      refstring.refname = tag["name"]
      refstring.content = tag.content
      refstring.comments = ""
      tag.children.each do |n|
        if n.comment?
          unless refstring.comments == ""
            refstring.comments += ","
          end
          refstring.comments += n.content
        end
      end
    end
    position += 1
    refstring.save
  end
  rev.instances_count = rev.instances_normal_count + rev.instances_broken_count
  rev.save
end

$t1 = Time.now
Article.find_each do |article|
  uri = URI(
    "https://en.wikipedia.org/w/api.php?" +
    "action=query" + "&" +
    "format=json" + "&" +
    "prop=revisions" + "&" +
    "rvlimit=50" + "&" +
    "rvprop=ids|timestamp|user|userid|comment|tags|size|content" + "&" +
    "pageids=#{article.pageid.to_s}")
  breakme = false
  wikiapidata = Net::HTTP.get_response(uri)
  wikijsondata = JSON.parse(wikiapidata.body)
  wikijsondata["query"]["pages"][article.pageid.to_s]["revisions"].each do |revision|
    if Revision.where(revid: revision["revid"]).exists? == false
      save_revision_info(article,revision)
    else
      breakme = true
      break
    end
  end

  if breakme == false
    while ! wikijsondata.keys.include?("batchcomplete") do
      conti = wikijsondata["continue"]["continue"]
      rvconti = wikijsondata["continue"]["rvcontinue"]
      uri2 = uri + "&continue=" + conti + "&rvcontinue=" + rvconti
      wikiapidata = Net::HTTP.get_response(uri2)
      wikijsondata = JSON.parse(wikiapidata.body)
      wikijsondata["query"]["pages"][article.pageid.to_s]["revisions"].each do |revision|
        if Revision.where(revid: revision["revid"]).exists? == false
          save_revision_info(article,revision)
        else
          breakme = true
          break
        end
      end
      if breakme == true
        break 
      end
    end
  else
    next
  end
end
$t2 = Time.now
