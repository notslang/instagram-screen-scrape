.PHONY: build unbuild

define DEVELOPMENT_BIN
#!/usr/bin/env node
require('coffee-script/register');
require('../lib/cli');
endef
export DEVELOPMENT_BIN

define PRODUCTION_BIN
#!/usr/bin/env node
require('../lib/cli');
endef
export PRODUCTION_BIN

build:
	cp -R lib src
	./node_modules/.bin/coffee --bare --compile lib
	find lib -iname "*.coffee" -exec rm '{}' ';'
	echo "$$PRODUCTION_BIN" > ./bin/index.js

unbuild:
	rm -rf lib
	mv src lib
	echo "$$DEVELOPMENT_BIN" > ./bin/index.js
