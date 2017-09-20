$t1 = Time.now

ArticleRevision.find_each do |r|
  unless r.content == nil
    mwtext = r.content
    refindex = 0
    refendex = 0
    while TRUE do
      refindex = mwtext.index("<ref", refendex)
      if refindex == nil
        break
      end
      ## Here is the really crazy code that parses tags. I'd use Nokogiri for the whole thing but I need to also catch broken tags
      ## WHO IT SEES FIRST
      # 
      # slashref -> short
      # 
      # nextbrack
      #     if part of refendex -> normal
      #     else -> broken
      #     
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
        else
          reftype = 'broken'
          refendex = nextbrack
        end
      elsif ((slashref < nextbrack) || (nextbrack == -1)) && ((slashref < refendex) || (refendex == -1)) && (slashref != -1)
        #NOTE THAT THIS is also triggered by <references/> make sure to catch it.
        reftype = 'short'
        refendex = slashref + 2
      else
        #lolwtf
        puts "DUDE WTF"
        break
      end

      refstring = ReferenceItem.new
      refstring.parent_revision_id = r.revision_id
      refstring.reference_type = reftype
      refstring.reference_string = mwtext[refindex,refendex-refindex]

      unless reftype == "broken"
        doc = Nokogiri::HTML(refstring.reference_string)
        tag = doc.css("ref")[0]
        unless tag == nil
          refstring.reference_name = tag["name"]
          refstring.reference_content = tag.content
          refstring.comments = ""
          tag.children.each do |n|
            if n.comment?
              unless refstring.comment == ""
                refstring.comment += ","
              end
              refstring.comment += n.content
            end
          end
        end
      end

      refstring.save
    end
  end
end
$t2 = Time.now
puts "ALL DONE"
puts "ALL DONE"
puts "ALL DONE"
puts "ALL DONE"
puts "ALL DONE"
