require 'json'
require 'net/http'
require 'nokogiri'

$revs = ArticleRevision.all
=begin
$t1 = Time.now



$errormsgs = Array.new

########################
# FOR GRABBING PARSETREES GIVEN EXISTING ROWS
#############################
$revs.each do |r|
  if r.parsetree == nil
    uri = URI('https://en.wikipedia.org/w/api.php?action=parse&format=json&prop=parsetree&contentmodel=wikitext&oldid='+r.revision_id)
    wikiapidata = Net::HTTP.get_response(uri)
    wikijsondata = JSON.parse(wikiapidata.body)
    if wikijsondata.keys.include? "error"
      $errormsgs << {id: r.revision_id,code: wikijsondata["error"]["code"],msg: wikijsondata["error"]["info"]}
    else
      r.parsetree = wikijsondata["parse"]["parsetree"]["*"]
      r.save
    end
  end
end

$t2 = Time.now

############################
# FOR CHOPPING UP REVISION CONTENT INTO REF STRINGS
############################
$refbreaks = Array.new
$revs.each do |r|
  unless r.content == nil
    mwtext = r.content
    refindex = 0
    refendex = 0
    lastindex = 0
    while TRUE do
      refindex = mwtext.index("<ref", refendex)
      if refindex == nil
        break
      end
      nextref = mwtext.index("<ref", refindex + 1)
      nextref = !nextref ? -1 : nextref  #Convert nils to -1
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
        $refbreaks << r.revision_id
        break
      end
      refstring = ReferenceInstance.new
      refstring.parent_revision_id = r.revision_id
      refstring.reference_type = reftype
      refstring.reference_string = mwtext[refindex,refendex-refindex]
      refstring.save
      lastindex = refendex
    end
  end
end
=end
$t3 = Time.now

##################################################
# FOR EXTRACTING REF NODES FROM PARSETREES
################################################

$whoanode = Array.new
$revs.each do |r|
  unless r.parsetree == nil
    doc = Nokogiri::XML(r.parsetree)
    exlist = doc.xpath("//ext")
    exlist.each do |node|
      if node.at("name").inner_html == 'ref'
        refname = node.at("attr").inner_html
        if node.at("inner")
          refcontent = node.at("inner").inner_html
          reftype = 'normal'
        else
          refcontent = nil
          reftype = 'short'
        end
        refstring = ReferenceUsage.new
        refstring.parent_revison_id = r.revision_id
        refstring.reference_type = reftype
        refstring.reference_name = refname
        refstring.reference_content = refcontent
        refstring.save
      else
      	$whoanode << {revision_id: r.revision_id, type: node.at("name").inner_html}
      end
    end
  end
end
$t4 = Time.now

########################################
# FOR FINDING NON REF EXT NODES
#######################################
$whoanode = Array.new
$revs.each do |r|
  unless r.parsetree == nil
    doc = Nokogiri::XML(r.parsetree)
    exlist = doc.xpath("//ext")
    exlist.each do |node|
      unless node.at("name").inner_html == 'ref'
      	$whoanode << {revision_id: r.revision_id, type: node.at("name").inner_html}
      end
    end
  end
end

Hash[$whoanode.collect {|x| x[:type]}.group_by {|x| x}.map {|k,v| [k,v.count]}]
types = $whoanode.collect {|x| x[:type]}
{"math"=>2526, "nowiki"=>92, "Ref"=>6, "gallery"=>1330, "references"=>16}

#######################################
# FOR GRABBING NON REF EXT NODES
#######################################

elnodo = Array.new
r = ArticleRevision.find_by(revision_id: '789785293')
doc = Nokogiri::XML(r.parsetree)
exlist = doc.xpath("//ext")
exlist.each do |node|
  unless node.at("name").inner_html == 'ref'
  	elnodo << {revision_id: r.revision_id, type: node.at("name").inner_html, node: node}
  end
end


#https://en.wikipedia.org/w/api.php?action=parse&format=jsonfm&prop=parsetree&contentmodel=wikitext&oldid=719915231

##################################
# FOR FINDING UNIQUE NON REF EXT NODES
##################################
types = $whoanode.collect do |x|
 if x[:type] == "Ref"
  x[:revision_id]
 end
end.uniq

#instances = ReferenceInstance.all
#usages = ReferenceUsage.all

##############################
# FOR GRABBING A LIST OF REFIDS
###############################
revids = ArticleRevision.pluck("revision_id")



numinstances = ReferenceInstance.group(:parent_revision_id).count
numusages = ReferenceUsage.group(:parent_revision_id).count
