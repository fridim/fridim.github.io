#  Where the markdown files are
mddir = .
GPGkey = 0x0A74F4B1A9903389 # gpg key used to sign .md files

mdfiles = $(shell find $(mddir)/ -name "*.md" ! -iname '*draft*') index.md
htmlfiles = $(mdfiles:.md=.html)
signedfiles = $(mdfiles:.md=.md.asc)

# draft only for preview (no push)
draftmd = $(shell find $(mddir)/ -iname '*draft*md')
drafthtml = $(draftmd:.md=.html)

.PHONY: all push

all: $(htmlfiles) $(signedfiles) $(drafthtml)

%.html: SHELL:=/bin/bash
%.html: %.md Makefile inc/head.html inc/disqus.html %.md.asc
	(cat inc/head.html ; \
		[ -e "inc/$@" ] && cat "inc/$@"; \
		markdown_py -x codehilite <(./toc.rb $<) ;\
		[ "$@" != "index.html" ] && cat inc/disqus.html ;\
		echo '<hr /><div id="footer">$$&nbsp;from&nbsp;<a href="../$<">$<</a>&nbsp;(<a href="../$<.asc">GPG sig</a>)&nbsp;$(shell date|sed "s/ /\&nbsp;/g")&nbsp;$$<br />Powered by <a href="/Makefile">Make</a> &amp; <a href="https://en.wikipedia.org/wiki/Markdown">Markdown</a> </div>'; \
		echo "</body></html>") > $@

%.md.asc: %.md
	@rm -f $@
	gpg -u $(GPGkey) --clearsign $<
