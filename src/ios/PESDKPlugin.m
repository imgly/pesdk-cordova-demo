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

@property(strong) CDVInvokedUrlCommand *lastCommand;
@property(nonatomic, strong) UINavigationController *navigationController;

@end

@implementation PESDKPlugin

+ (void)initialize {
    if (self == [PESDKPlugin self]) {
        // [PESDK unlockWithLicenseAt:[[NSBundle mainBundle] URLForResource:@"IOS_LICENSE" withExtension:nil]];
    }
}

#pragma mark - Cordova

- (void)finishCommandWithResult:(CDVPluginResult *)result {
    if (self.lastCommand != nil) {
        [self.commandDelegate sendPluginResult:result callbackId:self.lastCommand.callbackId];
        self.lastCommand = nil;
    }
}

#pragma mark - Public API

- (void)present:(CDVInvokedUrlCommand *)command {
    if (self.lastCommand == nil) {
        self.lastCommand = command;
        
        
        IMGLYConfiguration *configuration = [[IMGLYConfiguration alloc] initWithBuilder:^(IMGLYConfigurationBuilder * _Nonnull builder) {
            // Customize the SDK to match your requirements:
            // ...eg.:
            // [builder setBackgroundColor:[UIColor whiteColor]];
        }];
        
        IMGLYCameraViewController *cameraViewController = [[IMGLYCameraViewController alloc] initWithConfiguration:configuration];
        [cameraViewController setCompletionBlock:^(UIImage * _Nullable image, NSURL * _Nullable url) {
            IMGLYPhotoEditViewController *photoEditViewController = [[IMGLYPhotoEditViewController alloc] initWithPhoto:image configuration:configuration];
            photoEditViewController.delegate = self;
            IMGLYToolbarController *toolbarController = [IMGLYToolbarController new];
            [toolbarController pushViewController:photoEditViewController animated:YES completion:nil];
            [self.viewController dismissViewControllerAnimated:YES completion:^{
                [self.viewController presentViewController:toolbarController animated:YES completion:nil];
            }];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController presentViewController:cameraViewController animated:YES completion:nil];
        });
    }
}

- (void)closeControllerWithResult:(CDVPluginResult *)result {
    [self.viewController dismissViewControllerAnimated:YES completion:^{
        [self finishCommandWithResult:result];
    }];
}

#pragma mark - Filesystem Workaround

// See https://issues.apache.org/jira/browse/CB-8032 for context about
// these methods.

- (NSURL *)urlTransform:(NSURL *)url {
    NSURL *urlToTransform = url;

    // For backwards compatibility - we check if this property is there
    SEL sel = NSSelectorFromString(@"urlTransformer");
    if ([self.commandDelegate respondsToSelector:sel]) {
        // Grab the block from the commandDelegate
        NSURL * (^urlTransformer)(NSURL *) = ((id(*)(id, SEL))objc_msgSend)(self.commandDelegate, sel);
        // If block is not null, we call it
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

    // Generate unique file name
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

    // Save file
    if ([data writeToFile:filePath options:NSAtomicWrite error:&err]) {
        url = [self urlTransform:[NSURL fileURLWithPath:filePath]];
    }
    return url;
}

#pragma mark - IMGLYPhotoEditViewControllerDelegate

// The PhotoEditViewController did save an image.
- (void)photoEditViewController:(IMGLYPhotoEditViewController *)photoEditViewController didSaveImage:(UIImage *)image imageAsData:(NSData *)data {
    if (image) {
        [self saveImageToPhotoLibrary:image];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [self closeControllerWithResult:result];
    }
}

// The PhotoEditViewController was cancelled.
- (void)photoEditViewControllerDidCancel:(IMGLYPhotoEditViewController *)photoEditViewController {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [self closeControllerWithResult:result];
}

// The PhotoEditViewController could not create an image.
- (void)photoEditViewControllerDidFailToGeneratePhoto:(IMGLYPhotoEditViewController *)photoEditViewController {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Image editing failed."];
    [self closeControllerWithResult:result];
}

#pragma mark - Result Handling

- (void)saveImageToPhotoLibrary:(UIImage *)image {
    [self.commandDelegate runInBackground:^{
        __block PHObjectPlaceholder *assetPlaceholder = nil;
        
        // Apple did a great job at making this API convoluted as fuck.
        PHPhotoLibrary *photos = [PHPhotoLibrary sharedPhotoLibrary];
        [photos performChanges:^{
            // Request creating an asset from the image.
            PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            // Get a placeholder for the new asset.
            assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        } completionHandler:^(BOOL success, NSError *error) {
            CDVPluginResult *result;
            if (success) {
                PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[ assetPlaceholder.localIdentifier ] options: nil].firstObject;
                if (asset != nil) {
                    // Fetch high quality image and save in folder
                    PHImageRequestOptions *operation = [[PHImageRequestOptions alloc] init];
                    operation.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                    [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                      options:operation
                                                                resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                                    CDVPluginResult *resultAsync;
                                                                    NSError *error = [info objectForKey:PHImageErrorKey];
                                                                    if (error != nil) {
                                                                        resultAsync = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                                                                    } else {
                                                                        NSURL *url = [self copyTempImageData:imageData withUTI:dataUTI];
                                                                        NSString *urlString = [url absoluteString];
                                                                        NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:urlString, @"url", dataUTI, @"uti", nil];
                                                                        resultAsync = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                                                    messageAsDictionary:payload];
                                                                    }
                                                                    
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        [self closeControllerWithResult:resultAsync];
                                                                    });
                                                                }];
                    return;
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                               messageAsString:@"Failed to load photo asset."];
                }
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:[error localizedDescription]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self closeControllerWithResult:result];
            });
        }];
    }];
}

@end
