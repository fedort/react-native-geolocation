//
//  BadElfController.h
//  RNCGeolocation
//
//  Created by Fedor Trojeglasow on 2020-03-14.
//  Copyright © 2020 Facebook. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface BadElfController : NSObject <EAAccessoryDelegate, NSStreamDelegate>

@property EAAccessory *accessory;
@property EASession *session;
@property NSMutableData *readData;
@property NSString *dataAsString;
@property NSMutableData *writeData;

- (EASession *)openSessionForProtocol:(NSString *)protocolString;
- (void)closeSession;
- (NSDictionary *)getLocationFromData;

@end
