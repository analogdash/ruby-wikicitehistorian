require 'net/http'
require 'json'
require_relative 'methods'
require 'nokogiri'

pageid = 142721 #MARCOS
uri = URI('https://en.wikipedia.org/w/api.php?action=parse&format=json&prop=parsetree&contentmodel=wikitext&pageid='+pageid.to_s)
wikiapidata = Net::HTTP.get_response(uri)
wikijsondata = JSON.parse(wikiapidata.body)
doc = Nokogiri::XML(wikijsondata["parse"]["parsetree"]["*"])
exlist = doc.xpath("//ext")

count = 0
refstrings2 = Array.new
exlist.each do |node|
  if node.at("name").inner_html == 'ref'
    refname = node.at("attr").inner_html
    if node.at("inner")
      refcontent = node.at("inner").inner_html
      reftype = 'normal'
    else
      refcontent = nil
      reftype = 'short'
    refstrings2 << {name: refname, type: reftype, content: reftext}
  else
    puts "whoa, it's a #{node.at("name").inner_html}"
  end
end

refstrings2.map {|r| r[:name]}


File.open("reffish.txt", "w") do |aFile|
  aFile.puts(refstrings2)
end
