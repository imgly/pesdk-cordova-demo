//
//  PESDKPlugin.h
//  PESDKPlugin
//
//  Created by Malte Baumann on 3/15/17.
//
//

#import <Cordova/CDV.h>
@import imglyKit;

@interface PESDKPlugin : CDVPlugin

- (void)present:(CDVInvokedUrlCommand *)command;

@end
