<p align="center">
  <img src="http://static.photoeditorsdk.com/logo.png" />
</p>

# PhotoEditor SDK Cordova Plugin Demo
This project shows how to easily integrate the [PhotoEditorSDK](https://www.photoeditorsdk.com?utm_source=Github&utm_medium=PESDK&utm_term=Cordova-Demo) into a Cordova application.

**THIS IS A DEMO**. This repository is not meant as a fully fledged Cordova plugin, but as a base for further development instead. You can copy the repository into your own apps folder and use the `cordova plugin add /path/to/plugin --link` command to add this plugin. You will most likely need to adjust the codebase to fit your requirements and to customize the PhotoEditor SDK. For customizations, take a look at the [PESDKPlugin.m](src/ios/PESDKPlugin.m) and [PESDKPlugin.java](src/android/PESDKPlugin.java) files. There you can alter the configurations to change colors, behaviour etc. and handle callbacks that are sent by our SDK.

## Example app
The example app demonstrates how to open the PESDKs camera and pass any taken or selected images to the editor. When an edited image is saved, its filepath is sent back to Cordova and displayed using a JavaScript alert. An app could then display this image in Cordova or send it to a backend.

## Note 
The PhotoEditorSDK is a product of 9Elements GmbH. 
Please [order a license](https://www.photoeditorsdk.com/pricing#contact/?utm_source=Github&utm_medium=PESDK&utm_term=Cordova-Demo). Please see `LICENSE.md` for licensing details.

## PhotoEditor SDK for iOS & Android
The [PhotoEditor SDK](https://www.photoeditorsdk.com/?utm_source=Github&utm_medium=PESDK&utm_term=Cordova-Demo) for iOS and Android are **fully customizable** photo editors which you can integrate into your React Native app within minutes.

## Installation

### iOS Configuration

The plugin adds the NSCameraUsageDescription and NSPhotoLibraryUsageDescription keys to your iOS apps Info.plist file. These are required as of iOS 10 and not setting them will cause your app to crash.
You can customize these messages to match your use case in the [plugin.xml](plugin.xml) file:

```
  <platform name="ios">
  
    <config-file target="*-Info.plist" parent="NSCameraUsageDescription">
      <string># YOUR TEXT HERE #</string>
    </config-file>
    <config-file target="*-Info.plist" parent="NSPhotoLibraryUsageDescription">
      <string># YOUR TEXT HERE #</string>
    </config-file>
    
  </platform>
```

### Android Configuration

No special configuration is needed for Android. Just require the plugin.

## Development

To run the example app that comes with this repository you need to execute the following commands from the root folder:
```
$ make
$ cp example/LICENSE_ANDROID example/platforms/android/assets
```
These add the iOS and Android platforms to the example app, install the `pesdk` plugin from the current directory and finally adds the required licenses for the PhotoEditor SDK.

Furthermore you need to add the LICENSE_IOS file to the Xcode project by opening [PESDKDemo.xcworkspace](example/platforms/ios/PESDKDemo.xcworkspace) and dragging the license file into Xcodes sidebar.

To run the Android and iOS samples you can then simply execute `cordova run android` or `cordova run ios` from the `example` subfolder. If the Android app crashes upon launch you most likely forgot the `cp LICENSE_ANDROID...` command mentioned above.

After you change source code in the native Android/Xcode IDE, make sure to **commit your changes back to the root folder** or you might overwrite your work! 

### Android
`make clean android` and a test apk is built. You can open `example/platforms/android` directly with Android Studio.
### iOS
`make clean ios` and a test project is built. It will build an xcode project in `example/platforms/ios`.
