# PhotoEditor SDK Cordova Plugin Demo

## NOTES



### iOS Configuration

Add entries to your config.xml describing how your app uses camera and photo library permissions. 
Customize these messages for your particular app.

```
  <platform name="ios">
  
    <config-file target="*-Info.plist" parent="NSCameraUsageDescription">
      <string>Uses your camera to snap pictures.</string>
    </config-file>
    <config-file target="*-Info.plist" parent="NSPhotoLibraryUsageDescription">
      <string>Accesses your photo library to save and open pictures.</string>
    </config-file>
    
  </platform>
```

### Android Configuration

No special configuration is needed for Android. Just require the plugin.

## Development

To run the example app that comes with this repository you need to execute the following commands from the root folder:
```
$ make
$ cp LICENSE_ANDROID example/platforms/android/assets
```
These add the iOS and Android platforms to the example app, install the `pesdk` plugin from the current directory and finally adds the required licenses for the PhotoEditor SDK.

After you change source code in the native Android/Xcode IDE, make sure to **commit your changes back to the root folder** or you might overwrite your work! 

### Android
`make clean android` and a test apk is built. You can open [example/platforms/android](the Android project) directly with Android Studio.
### iOS
`make clean ios` and a test project is built. It will build an xcode project in [example/platforms/ios](example/platforms/ios).
