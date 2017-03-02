#!/usr/bin/env ruby

toc = String.new
buffer = String.new
id = 0
toc_found=false

ARGF.each do |line|
  toc_found=true if line =~ /%%TOC%%/

  if line.start_with?("#") && toc_found
    title = line.gsub("#", "").strip
    href = "toc-id-#{id}"
    id = id + 1
    buffer << "<a id='#{href}' />\n"
    toc << "  " * (line.count("#")-1) + "* [#{title}](\##{href})\n"
  end


  buffer << line
end

puts buffer.gsub('%%TOC%%', toc)
