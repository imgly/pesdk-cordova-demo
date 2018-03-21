<p align="center">
  <a target="_blank" href="https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo"><img src="http://static.photoeditorsdk.com/logo.png" alt="PhotoEditor SDK Logo"/></a>
</p>

# PhotoEditor SDK Cordova Plugin Demo
This project shows how to easily integrate the [PhotoEditor SDK](https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo) into a Cordova application.

**THIS IS A DEMO**. This repository is not meant as a fully fledged Cordova plugin, but as a base for further development instead. You can copy the repository into your own project and use the `cordova plugin add /path/to/plugin --link` command to add it to your app. You will most likely need to adjust the codebase to fit your requirements and to customize the PhotoEditor SDK. For customizations, take a look at the [PESDKPlugin.m](src/ios/PESDKPlugin.m) and [PESDKPlugin.java](src/android/PESDKPlugin.java) files. You can easily alter the configurations to change colors, behaviour etc. and handle callbacks that are sent by our SDK. For further reference take a look at our [documentation](http://docs.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo).

> :warning: You need to make sure that the app identifiers declared in your license file match the bundle/app identifiers used on iOS and Android.

## Example App
The included example app demonstrates how to open the PhotoEditor SDK's camera and pass any taken or selected images to the editor. When an edited image is saved, its filepath is sent back to Cordova and displayed using a JavaScript alert. An app could then display this image in Cordova or send it to a backend. If you want to edit an already existing image, you just need to path a path to the file (keep the file handling methods on both platforms in mind). To launch the example app, take a look at the *Development* section below.

## Note 
The PhotoEditorSDK is a product of 9elements GmbH. 
Please [order a license](https://www.photoeditorsdk.com/pricing/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo). Please see the included [LICENSE](LICENSE.md) for licensing details.

## PhotoEditor SDK for iOS & Android
The [PhotoEditor SDK](https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=Side_Projects&utm_content=Cordova-Demo) for iOS and Android are **fully customizable** photo editors which you can integrate into your Cordova app within minutes.

## Installation
In order to use the plugin within your Cordova app you need to follow some steps, detailed in the following paragraphs.

### iOS Configuration

The plugin adds the `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` keys to your iOS apps `Info.plist` file. These are required as of iOS 10 and not setting them will cause your app to crash.
You can customize these messages to match your use case in the [plugin.xml](https://github.com/imgly/pesdk-cordova-demo/blob/master/plugin.xml) file:

```
    <config-file target="*-Info.plist" parent="NSCameraUsageDescription">
      <string># YOUR TEXT HERE #</string>
    </config-file>
    <config-file target="*-Info.plist" parent="NSPhotoLibraryUsageDescription">
      <string># YOUR TEXT HERE #</string>
    </config-file>
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
