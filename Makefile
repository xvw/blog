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
