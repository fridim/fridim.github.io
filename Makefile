#  Where the markdown files are
mddir = notes
GPGkey = 0x0A74F4B1A9903389 # gpg key used to sign .md files

mdfiles = $(shell find $(mddir)/ -name "*.md" ! -iname '*draft*') index.md
adocfiles = $(shell find notes/ -name "*.adoc" ! -iname '*draft*')
htmlfiles = $(mdfiles:.md=.html) $(adocfiles:.adoc=.html)
signedfiles = $(mdfiles:.md=.md.asc.txt)

# draft only for preview (no push)
draftmd = $(shell find $(mddir)/ -iname '*draft*md')
drafthtml = $(draftmd:.md=.html)

.PHONY: all push

all: $(htmlfiles) $(signedfiles) $(drafthtml)
EnableDisqus = false

%.html: SHELL:=/bin/bash
%.html: %.adoc inc/disqus.adoc
	cp $< $<.tmp
	if [ $(EnableDisqus) = true ]; then cat inc/disqus.adoc >> $<.tmp; fi
	asciidoctor -o - $<.tmp > "$@"
	rm -f $<.tmp
%.html: %.md Makefile inc/head.html inc/disqus.html
	(cat inc/head.html ; \
		[ -e "inc/$@" ] && cat "inc/$@"; \
		markdown_py -x codehilite <(./toc.rb <(sed '/^%%sign%%/d' $<)) ;\
		[ $(EnableDisqus) = true ] && [ "$@" != "index.html" ] && cat inc/disqus.html ;\
		echo '<hr /><div id="footer">$$&nbsp;from&nbsp;<a href="../$<">$<</a>&nbsp;';\
		if [ -e $<.asc.txt ]; then \
		  echo '(<a href="/$<.asc.txt">GPG sig</a>)&nbsp;' ;\
		fi ;\
		echo "$(shell date|sed "s/ /\&nbsp;/g")" ;\
		echo '&nbsp;$$<br />Powered by <a href="/Makefile">Make</a> &amp; <a href="https://en.wikipedia.org/wiki/Markdown">Markdown</a> </div>' ;\
		cat inc/tail.html) > "$@"

%.md.asc.txt: %.md
	@rm -f $@
	@if grep -q '%%sign%%' $<; then \
          gpg -u $(GPGkey) --clearsign $< ;\
          mv $<.asc $@ ;\
        fi
