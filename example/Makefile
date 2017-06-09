.PHONY: all clean android ios

all: android ios

clean:
	cordova platform rm android || true
	cordova platform rm ios || true
	cordova plugin rm cordova-plugin-pesdk || true

android:
	cordova plugin add .. --link --nofetch
	cordova platform add android
	cordova build android
	@echo "Android project built at $$(pwd)/platforms/android"

prepare-android:
	cordova plugin add .. --link --nofetch
	cordova platform add android

rebuild-android:
	cordova plugin rm cordova-plugin-pesdk || true
	cordova plugin add .. --link
	cordova build android

ios:
	cordova plugin add .. --link --nofetch
	cordova platform add ios
	cordova build ios
	@echo "XCode project built at $$(pwd)/platforms/ios/PESDKDemo.xcodeproj"
