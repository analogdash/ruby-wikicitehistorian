def same_reference? (instance, usage)
  if instance.wikitext == usage.wikitext
    return true
  elsif instance.content == usage.content
    return true
  elsif instance.refname == usage.refname
    return true
  else
    return false
  end
end

@article = Article.first
@nextrev = Revision.where(pageid: @article.pageid).order(:revid).first

$t1 = Time.now

while true
  ReferenceInstance.where(revid: @nextrev.revid).find_each do |instance|
    foundflag = false
    ReferenceUsage.where(pageid: @article.pageid).where.not(lastseen: @nextrev.revid).find_each do |usage|
      if same_reference?(instance,usage)
        unless usage.current
          usage.update_attributes(skips: usage.skips+1)
        end
        instance.update_attributes(prevposition: usage.currentposition,
                                   prevrevid: usage.lastseen)
        usage.update_attrubutes(wikitext: instance.wikitext,
                                refname: instance.refname,
                                content: instance.content,
                                comments: instance.comments,
                                currentposition: instance.position,
                                appearances: usage.appearances + 1,
                                current: true,
                                lastseen: instance.revid)
        foundflag = true
        break
      end
    end
    if foundflag == false
      ReferenceUsage.create(pageid: @article.pageid,
                            wikitext: instance.wikitext,
                            refname: instance.refname,
                            content: instance.content,
                            comments: instance.comments,
                            currentposition: instance.position,
                            firstseen: instance.revid,
                            lastseen: instance.revid,
                            current: true,
                            appearances: 1)
    end
  end
  ReferenceUsage.where(pageid: @article.pageid, current: true).where.not(lastseen: @nextrev.revid).update_all(current: false)
  @article.update_attributes(lastrevid: @nextrev.revid)
end while @nextrev = Revision.where(parentid: @nextrev.revid).take

$t2 = Time.now
