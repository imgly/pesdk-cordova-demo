//
//  PESDKPlugin.m
//  PESDKPlugin
//
//  Created by Malte Baumann on 3/15/17.
//
//

#import <Photos/Photos.h>
#import <objc/message.h>
#import "PESDKPlugin.h"
@import imglyKit;

// UIColorFromRBG via http://stackoverflow.com/a/3532264/4403530
#define UIColorFromRGB(rgbValue)                                                                                       \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0                                               \
                    green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0                                                  \
                     blue:((float)(rgbValue & 0xFF)) / 255.0                                                           \
                    alpha:1.0]

@interface PESDKPlugin () <IMGLYPhotoEditViewControllerDelegate, UIImagePickerControllerDelegate>

@property(strong, nonatomic) UINavigationController *overlay;
@property(strong) CDVInvokedUrlCommand *lastCommand;
@property(readwrite, assign) BOOL hasPendingOperation;
@property(strong) IMGLYConfiguration *imglyConfig;

@end

@implementation PESDKPlugin

@synthesize hasPendingOperation;

+ (void)initialize {
    if (self == [PESDKPlugin self]) {
        // static initialization here
    }
}

- (void)configureImgly {
    if (self.imglyConfig == nil) {
        void (^configurationBuilder)(IMGLYConfigurationBuilder *) = ^(IMGLYConfigurationBuilder *builder) {
          [builder configureCameraViewController:^(IMGLYCameraViewControllerOptionsBuilder *cameraOptions) {
            [cameraOptions setAllowedRecordingModesAsNSNumbers:@[ [NSNumber numberWithInt:RecordingModePhoto] ]];
          }];
          [builder configurePhotoEditorViewController:^(IMGLYPhotoEditViewControllerOptionsBuilder *editorOptions){
              // Configure the editor...
          }];
        };

        self.imglyConfig = [[IMGLYConfiguration alloc] initWithBuilder:configurationBuilder];
    }
}

#pragma mark - Cordova

- (BOOL)requestCommand:(CDVInvokedUrlCommand *)command {
    // Enforce one command running at a time.
    BOOL go = NO;
    @synchronized(self) {
        if (_lastCommand == nil) {
            _lastCommand = command;
            go = TRUE;
        }
    }
    return go;
}

- (void)finishCommand:(CDVPluginResult *)result {
    NSString *cb = nil;
    @synchronized(self) {
        if (_lastCommand != nil) {
            cb = _lastCommand.callbackId;
            _lastCommand = nil;
        }
    }
    if (cb != nil) {
        [self.commandDelegate sendPluginResult:result callbackId:cb];
    }
}

#pragma mark - Error Handling

- (NSError *)errorAccessDenied:(NSString *)msg {
    return [NSError errorWithDomain:@"com.photoeditorsdk.cordova"
                               code:1
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
}

#pragma mark - Permissions

- (void)acquireCameraPermission:(void (^)(NSError *error))callback {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        callback(NULL);
    } else {
        [AVCaptureDevice
            requestAccessForMediaType:AVMediaTypeVideo
                    completionHandler:^(BOOL granted) {
                      if (granted) {
                          callback(NULL);
                      } else {
                          [self requestManualSettings:@"Please enable Camera access."
                                         withCallback:^{
                                           AVAuthorizationStatus authStatus2 =
                                               [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                                           if (authStatus2 == AVAuthorizationStatusAuthorized) {
                                               callback(NULL);
                                           } else {
                                               callback([self errorAccessDenied:@"Camera permission denied!"]);
                                           }
                                         }];
                      }
                    }];
    }
}

- (void)retryLibraryPermission:(void (^)(NSError *error))callback {
    [self requestManualSettings:@"Please enable Photos access."
                   withCallback:^{
                     PHAuthorizationStatus authStatus2 = [PHPhotoLibrary authorizationStatus];
                     if (authStatus2 == PHAuthorizationStatusDenied) {
                         callback([self errorAccessDenied:@"Media library access denied."]);
                     } else {
                         callback(NULL);
                     }
                   }];
}

- (void)handleLibraryPermission:(void (^)(NSError *error))callback withStatus:(PHAuthorizationStatus)authStatus {
    switch (authStatus) {
    case PHAuthorizationStatusDenied:
        [self retryLibraryPermission:callback];
        break;
    case PHAuthorizationStatusRestricted:
        callback(NULL);
        break;
    case PHAuthorizationStatusAuthorized:
        callback(NULL);
        break;
    case PHAuthorizationStatusNotDetermined:
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newAuthStatus) {
          [self handleLibraryPermission:callback withStatus:newAuthStatus];
        }];
        break;
    }
}

- (void)acquireLibraryPermission:(void (^)(NSError *error))callback {
    [self handleLibraryPermission:callback withStatus:[PHPhotoLibrary authorizationStatus]];
}

- (void)acquireNecessaryPermissions:(void (^)(NSError *error))callback {
    [self acquireCameraPermission:^(NSError *cameraError) {
      if (cameraError == NULL) {
          [self acquireLibraryPermission:callback];
      } else {
          callback(cameraError);
      }
    }];
}

#pragma mark - Public API

- (void)present:(CDVInvokedUrlCommand *)command {
    PESDKPlugin *this = self;
    if ([self requestCommand:command]) {
        [self configureImgly];
        NSDictionary *args = [command argumentAtIndex:0];
        NSInteger sourceType = 1; // camera
        if (args != NULL) {
            id sourceTypeVal = [args objectForKey:@"sourceType"];
            if (sourceTypeVal != NULL) {
                sourceType = [sourceTypeVal integerValue];
            }
        }
        [self acquireNecessaryPermissions:^(NSError *error) {
          if (error == NULL) {
              PESDKPlugin *this = self;
              IMGLYCameraViewController *cameraCtl =
                  [[IMGLYCameraViewController alloc] initWithConfiguration:self.imglyConfig];
              cameraCtl.completionBlock = ^(UIImage *img, NSURL *url) {
                [self imglyCameraCompleted:img withUrl:url];
              };
              self.overlay = [[UINavigationController alloc] initWithRootViewController:cameraCtl];
              [self.overlay setToolbarHidden:YES];
              [self.overlay setNavigationBarHidden:YES];
              self.overlay.view.frame = self.viewController.view.frame;
              self.hasPendingOperation = YES;
              // self.overlay.delegate = this;
              // Perform UI operations on the main thread.
              dispatch_async(dispatch_get_main_queue(), ^{
                [this.viewController presentViewController:self.overlay animated:YES completion:nil];
              });
          } else {
              [this finishCommand:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsString:[error localizedDescription]]];
          }
        }];
    }
}

- (void)closeControllerWithResult:(CDVPluginResult *)result {
    PESDKPlugin *this = self;
    [self.overlay dismissViewControllerAnimated:YES
                                     completion:^{
                                       [this finishCommand:result];
                                       this.hasPendingOperation = NO;
                                     }];
}

- (NSURL *)urlTransform:(NSURL *)url {
    // See https://issues.apache.org/jira/browse/CB-8032 for context about this
    // method.

    NSURL *urlToTransform = url;

    // for backwards compatibility - we check if this property is there
    SEL sel = NSSelectorFromString(@"urlTransformer");
    if ([self.commandDelegate respondsToSelector:sel]) {
        // grab the block from the commandDelegate
        NSURL * (^urlTransformer)(NSURL *) = ((id(*)(id, SEL))objc_msgSend)(self.commandDelegate, sel);
        // if block is not null, we call it
        if (urlTransformer) {
            urlToTransform = urlTransformer(url);
        }
    }

    return urlToTransform;
}

- (NSString *)tempFilePath:(NSString *)extension {
    NSString *docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
    NSFileManager *fileMgr = [[NSFileManager alloc] init]; // recommended by Apple (vs [NSFileManager
                                                           // defaultManager]) to be threadsafe
    NSString *filePath;

    // generate unique file name
    int i = 1;
    do {
        filePath = [NSString stringWithFormat:@"%@/%@%d.%@", docsPath, @"PESDKPlugin_", i++, extension];
    } while ([fileMgr fileExistsAtPath:filePath]);

    return filePath;
}

- (NSURL *)copyTempImageData:(NSData *)data withUTI:(NSString *)uti {
    NSString *filePath = [self tempFilePath:uti];
    NSError *err = nil;
    NSURL *url = nil;

    // save file
    if ([data writeToFile:filePath options:NSAtomicWrite error:&err]) {
        url = [self urlTransform:[NSURL fileURLWithPath:filePath]];
    }
    return url;
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"Image picker captured image.");
    PESDKPlugin *this = self;
    [self.commandDelegate runInBackground:^{
      UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
      __block PHObjectPlaceholder *assetPlaceholder = nil;
      // Apple did a great job at making this API convoluted as fuck.
      PHPhotoLibrary *photos = [PHPhotoLibrary sharedPhotoLibrary];
      [photos performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        // Get a placeholder for the new asset.
        assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
      }
          completionHandler:^(BOOL success, NSError *error) {
            NSLog(@"Finished adding asset to album. %@", (success ? @"Success" : error));
            CDVPluginResult *result;
            if (success) {
                PHAsset *asset =
                    [PHAsset
                        fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObjects:assetPlaceholder.localIdentifier, nil]
                                                options:nil]
                        .firstObject;
                if (asset != nil) {
                    PHImageRequestOptions *opts = [[PHImageRequestOptions alloc] init];
                    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                    [[PHImageManager defaultManager]
                        requestImageDataForAsset:asset
                                         options:opts
                                   resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation,
                                                   NSDictionary *info) {
                                     CDVPluginResult *resultAsync;
                                     NSError *error = [info objectForKey:PHImageErrorKey];
                                     if (error != nil) {
                                         resultAsync = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                         messageAsString:[error localizedDescription]];
                                     } else {
                                         // Now that we finally have saved the image,
                                         // copy it where the browser can read it.
                                         NSURL *url = [this copyTempImageData:imageData withUTI:dataUTI];
                                         // NSURL *url = [self
                                         // urlTransform:((NSURL*)[info
                                         // objectForKey:@"PHImageFileURLKey"])];
                                         NSString *urlString = [url absoluteString];
                                         NSDictionary *payload = [NSDictionary
                                             dictionaryWithObjectsAndKeys:urlString, @"url", dataUTI, @"uti", nil];
                                         resultAsync = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                     messageAsDictionary:payload];
                                     }
                                     // Perform UI operations on the main thread.
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [this closeControllerWithResult:resultAsync];
                                     });
                                   }];
                    return; // we return result asynchronously in this case
                }
                {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                               messageAsString:@"Failed to load photo asset."];
                }
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:[error localizedDescription]];
            }
            // Perform UI operations on the main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
              [this closeControllerWithResult:result];
            });
          }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"Image picker cancelled.");
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@""];
    [self closeControllerWithResult:result];
}

- (void)openSettings {
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)requestManualSettings:(NSString *)reason withCallback:(void (^)())callback {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permission Request"
                                                                   message:reason
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Open Settings"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                            [self openSettings];
                                                            callback();
                                                          }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                           callback();
                                                         }];

    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.viewController presentViewController:alert animated:YES completion:nil];
    });
}

- (void)imglyCameraCompleted:(UIImage *)img withUrl:(NSURL *)url {
    if (img == nil) {
        [self imagePickerControllerDidCancel:nil];
    } else {
        IMGLYPhotoEditViewController *photoCtl =
            [[IMGLYPhotoEditViewController alloc] initWithPhoto:img configuration:self.imglyConfig];
        IMGLYToolbarController *toolbarController = [IMGLYToolbarController new];
        [toolbarController pushViewController:photoCtl animated:NO completion:NULL];
        photoCtl.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.overlay pushViewController:toolbarController animated:YES];
        });
    }
}

#pragma mark - IMGLYPhotoEditViewControllerDelegate

- (void)photoEditViewController:(IMGLYPhotoEditViewController *)photoEditViewController didSaveImage:(UIImage *)image imageAsData:(NSData *)data {
    NSLog(@"Did finish with image");
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:image, UIImagePickerControllerOriginalImage, image,
                          UIImagePickerControllerEditedImage, nil];
    [self imagePickerController:nil didFinishPickingMediaWithInfo:info];
}

- (void)photoEditViewControllerDidCancel:(IMGLYPhotoEditViewController *)photoEditViewController {
    [self imagePickerControllerDidCancel:nil];
}

- (void)photoEditViewControllerDidFailToGeneratePhoto:(IMGLYPhotoEditViewController *)photoEditViewController {
    CDVPluginResult *result =
    [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Image editing failed."];
    [self closeControllerWithResult:result];
}

@end
