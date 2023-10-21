pkg:
	./build.sh
	./pkg.sh

build: clean
	./build.sh

clean:
	rm -f *.zip *.sha*sum.txt version.txt *.omwaddon

web-clean:
	cd web && rm -rf build site/*.md sha256sums soupault-*-linux-x86_64.tar.gz

web: web-clean
	cd web && ./build.sh

web-debug: web-clean
	cd web && ./build.sh --debug

web-verbose: web-clean
	cd web && ./build.sh --verbose

clean-all: clean web-clean

local-web:
	cd web && python3 -m http.server -d build
