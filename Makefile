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

deploy: blog-rebuild
	git add _site/*
	git commit -m "Request deployement"
	git push

