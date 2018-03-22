<p align="center">
  <a target="_blank" href="https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo"><img src="http://static.photoeditorsdk.com/logo.png" alt="PhotoEditor SDK Logo"/></a>
</p>

# PhotoEditor SDK Cordova Plugin Demo
This project shows how to easily integrate the [PhotoEditor SDK](https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo) into a Cordova application.

**THIS IS A DEMO**. This repository is not meant as a fully fledged Cordova plugin, but as a base for further development instead. You can copy the repository into your own project and use the `cordova plugin add /path/to/plugin --link` command to add it to your app. You will most likely need to adjust the codebase to fit your requirements and to customize the PhotoEditor SDK. For customizations, take a look at the [PESDKPlugin.m](src/ios/PESDKPlugin.m) and [PESDKPlugin.java](src/android/PESDKPlugin.java) files. You can easily alter the configurations to change colors, behaviour etc. and handle callbacks that are sent by our SDK. For further reference take a look at our [documentation](http://docs.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo).

## License Files

> :warning: The SDK requires dedicated license files for each platform. If unavailable, the camera and editor will crash upon launch.

You need to add the LICENSE_IOS and LICENSE_ANDROID files to each project. This can be done manually by opening the PESDKDemo.xcworkspace using Xcode and dragging the license file into the sidebar, as well as copying the license file to the /platforms/android/app/main/assets folder for Android. 

Or automated by using Cordovas `resource-file` tags to link the files from the root directory. To do so, put your `LICENSE_ANDROID` and `LICENSE_IOS` files in the root folder of your project and then add the following lines to your `config.xml`:

Within the Android platform tag (supported starting `cordova-android-7.0`):
```xml
<platform name="android">
  <resource-file src="LICENSE_ANDROID" target="app/src/main/assets/LICENSE_ANDROID" />
</platform>
```

Within the iOS platform tag:
```xml
<platform name="ios">
  <resource-file src="LICENSE_IOS" />
</platform>
```

> :warning: You need to make sure that the app identifiers declared in your license files match the bundle/app identifiers used on iOS and Android.

## Example App
The included example app demonstrates how to open the PhotoEditor SDK's camera and pass any taken or selected images to the editor. When an edited image is saved, its filepath is sent back to Cordova and displayed using a JavaScript alert. An app could then display this image in Cordova or send it to a backend. If you want to edit an already existing image, you just need to path a path to the file (keep the file handling methods on both platforms in mind). To launch the example app, take a look at the *Development* section below.

## Note 
The PhotoEditorSDK is a product of 9elements GmbH. 
Please [order a license](https://www.photoeditorsdk.com/pricing/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo). Please see the included [LICENSE](LICENSE.md) for licensing details.

## PhotoEditor SDK for iOS & Android
The [PhotoEditor SDK](https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo) for iOS and Android are **fully customizable** photo editors which you can integrate into your Cordova app within minutes.

## Installation
In order to use the plugin within your Cordova app you need to provide license files for both platforms as mentioned above. Once these are linked correctly, you'll need to do a few more minor configurations:

### iOS Configuration

Since iOS 10 it's mandatory to provide an usage description in the `info.plist` if trying to access privacy-sensitive data. These are required and not setting them will cause your app to crash.

This plugins requires the following usage descriptions:

- `NSCameraUsageDescription` specifies the reason for your app to access the device's camera.
- `NSPhotoLibraryUsageDescription` specifies the reason for your app to access the user's photo library.

To add these entries into the `info.plist`, you can use the `edit-config` tag in the `config.xml` like this:

```
<edit-config target="NSCameraUsageDescription" file="*-Info.plist" mode="merge">
    <string># YOUR TEXT HERE #</string>
</edit-config>
```

```
<edit-config target="NSPhotoLibraryUsageDescription" file="*-Info.plist" mode="merge">
    <string># YOUR TEXT HERE #</string>
</edit-config>
```

### Android Configuration

No special configuration is needed for Android. Just require the plugin.

## Development
The example app was created by starting a new Cordova app, adding the iOS and Android platforms and linking the plugin using the `cordova plugin add /path/to/plugin --link` command mentioned above.

To run the Android and iOS samples you can then simply execute `cordova run android` or `cordova run ios` from the `example` subfolder.

If you make changes to the plugin in the root directory, you'll likely have to remove and add the plugin to your example project again to make sure the updated source code is used.

## License
Please see [LICENSE](https://github.com/imgly/pesdk-html5-rails/blob/master/LICENSE.md) for licensing details.

## Authors and Contributors
Made 2013-2018 by @9elements

## Support or Contact
Contact contact@photoeditorsdk.com for support requests or to upgrade to an enterprise licence.
