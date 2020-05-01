//
//  BadElfController.m
//  RNCGeolocation
//
//  Created by Fedor Trojeglasow on 2020-03-14.
//  Copyright © 2020 Facebook. All rights reserved.
//
#import "BadElfController.h"

@implementation BadElfController : NSObject

- (EASession *)openSessionForProtocol:(NSString *)protocolString
{
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
    _accessory = nil;
    _session = nil;

    for (EAAccessory *obj in accessories)
    {
        if ([[obj protocolStrings] containsObject:protocolString])
        {
            _accessory = obj;
            break;
        }
    }

    if (_accessory)
    {
        _session = [[EASession alloc] initWithAccessory:_accessory forProtocol:protocolString];

        if (_session)
        {
            [[_session inputStream] setDelegate:self];
            [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[_session inputStream] open];
            [[_session outputStream] setDelegate:self];
            [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[_session outputStream] open];
            //[_session autorelease];
        }
    }

    return _session;
}

- (void)closeSession {
    [[_session inputStream] close];
    [[_session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[_session inputStream] setDelegate:nil];
    
    [[_session outputStream] close];
    [[_session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[_session outputStream] setDelegate:nil];
    
    _session = nil;
    _writeData = nil;
    _readData = nil;
}

- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventHasBytesAvailable:
            // Process the incoming stream data.
            [self updateReadData];
            break;
        case NSStreamEventHasSpaceAvailable:
            // Send the next queued command.
            break;
        default:
            break;
    }
}

-(void)updateReadData
{
    NSUInteger bufferSize = 128;
    uint8_t buffer[bufferSize];
    
    while ([[_session inputStream] hasBytesAvailable] == true)
    {
        NSInteger bytesRead = [[_session inputStream] read:buffer maxLength:bufferSize];
        if (_readData == nil) {
            _readData = [[NSMutableData alloc] init];
        }
        
        [_readData appendBytes:buffer length:bytesRead];
        _dataAsString = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BESessionDataReceivedNotification" object:nil];
    }
}

- (NSDictionary *)getLocationFromData;
{
    NSArray *nmeaValues = [_dataAsString componentsSeparatedByString:@","];
    
    if ([[nmeaValues objectAtIndex:0] isEqualToString:@"$GPGGA"]) {
        // latitude = dd + mm.mmmmm from ddmm.mmmm nmea sentence
        double dd = [nmeaValues[2] intValue] / 100;
        double mm = [nmeaValues[2] doubleValue] - (dd * 100);
        double latitude = dd + (mm/60);
        
        // longitude = ddd + mm.mmmm/60 from dddmm.mmmm nmea sentence
        double longddd = [nmeaValues[4] intValue] / 100;
        double longmm =[nmeaValues[4] doubleValue] - (longddd * 100);
        double longitude = longddd + (longmm/60);
        
        if (latitude == 0 && longitude == 0) return nil;
        
        if ([nmeaValues[3] isEqualToString:@"S"]) latitude = latitude * -1;
        if ([nmeaValues[5] isEqualToString:@"W"]) longitude = longitude * -1;
        
        return @{
        @"coords": @{
            @"latitude": @(latitude),
            @"longitude": @(longitude),
            @"altitude": @([nmeaValues[9] doubleValue]),
            @"accuracy": @(-1), //(nmeaValues[7]), // 7 - number of satalites
            @"altitudeAccuracy": @(-1), // todo
            @"heading": @(-1), // todo
            @"speed": @(-1), // todo
            },
        @"timestamp": @([[NSDate date] timeIntervalSince1970] * 1000) // in ms
        };
    }
    else return nil;
}

@end
