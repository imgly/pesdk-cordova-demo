.PHONY: all android ios clean prepare copy-to-src

all: android ios

clean:
	make -C example clean

android: node_modules
	cd example && make android

ios: node_modules
	cd example && make ios

copy-to-src:
	@find example/platforms/android/src/com/photoeditorsdk/cordova -regex ".*java" -exec sh -c 'cp -f "{}" src/android/$$(basename "{}")' \;

node_modules:
	npm install
