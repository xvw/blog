all: base-build blog-rebuild

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
	rsync -avr --delete --exclude='.git'  _site/ site/
	cd site \
	  && git checkout master \
	  && git add . \
	  && git commit -m 'site update' \
	  && git push origin master
	git add site
	git commit -m 'site update'
	git push origin master
