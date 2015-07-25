build:
	cp -R lib src
	./node_modules/.bin/coffee -c lib
	find lib -iname "*.coffee" -exec rm '{}' ';'

unbuild:
	rm -rf lib
	mv src lib
