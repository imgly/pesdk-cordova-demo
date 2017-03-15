.PHONY: all clean android ios

all: android ios

clean:
	cordova platform rm android || true
	cordova platform rm ios || true
	cordova plugin rm PESDK || true

android:
	cordova plugin add .. --link
	cordova platform add android
	cordova build android
	@echo "Android project built at $$(pwd)/platforms/android"

prepare-android:
	cordova plugin add .. --link
	cordova platform add android

rebuild-android:
	cordova plugin rm PESDK || true
	cordova plugin add .. --link
	cordova build android

ios:
	cordova plugin add .. --link
	cordova platform add ios
	cordova build ios
	@echo "XCode project built at $$(pwd)/platforms/ios/PESDKDemo.xcodeproj"
