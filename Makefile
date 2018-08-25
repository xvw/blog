.PHONY: post-history caml-clean clean

all: player.bc.js base-build blog-rebuild

base-build:
	stack build

blog-build:
	stack exec blog build

blog-clean:
	stack exec blog clean

blog-rebuild:
	stack exec blog rebuild

watch:
	stack exec blog watch

push: blog-rebuild
	git submodule update --remote --merge
	rsync -avr --delete --exclude-from '.publishignore'  _site/ deployement/
	# cp CNAME deployement/CNAME
	cp 404.html deployement/404.html
	cd deployement \
	  && git checkout master \
	  && git add . \
	  && git commit -m 'site update' \
	  && git push origin master
	git add deployement
	git commit -m 'site update'
	git push origin master


%.png : graph/%.dot
	dot -Tpng -o images/$(@) $(<)

caml-clean:
	dune clean

clean: blog-clean caml-clean

%.bc.js:
	dune build @install
	dune install
	dune external-lib-deps --missing player/$(@)
	dune build player/$(@) --profile release
	cp _build/default/player/player.bc.js js/player.js

js: player.bc.js


post-history: zipper-init.png zipper-init2.png  zipper-init3.png zipper-init4.png zipper-init5.png zipper-init6.png zipper-init7.png blog-rebuild
