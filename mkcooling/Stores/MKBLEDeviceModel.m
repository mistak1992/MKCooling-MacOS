//
//  MKBLEDeviceModel.m
//  mkcooling
//
//  Created by mist on 2020/6/9.
//  Copyright © 2020 mist. All rights reserved.
//

#import "MKBLEDeviceModel.h"

#import "MKConvertor.h"



@implementation MKBLEDeviceModel

- (instancetype)initWithManufactureData:(NSData *)manufactureData andUUIDString:(NSString *)UUIDString{
    if (self = [super init]) {
        NSString *manufaceturerHexStr = [[MKConvertor hexStringFromData:manufactureData] lowercaseString];
        _pId = [manufaceturerHexStr substringWithRange:NSMakeRange(4, 4)];
        _mac = [manufaceturerHexStr substringWithRange:NSMakeRange(8, 12)];
        _UUIDString = UUIDString;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_pId forKey:@"pId"];
    [coder encodeObject:_mac forKey:@"mac"];
    [coder encodeObject:_UUIDString forKey:@"UUIDString"];
    [coder encodeInteger:_lifeLong forKey:@"lifeLong"];
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    if ([super init]) {
        _pId = [coder decodeObjectForKey:@"pId"];
        _mac = [coder decodeObjectForKey:@"mac"];
        self.UUIDString = [coder decodeObjectForKey:@"UUIDString"];
        self.lifeLong = [coder decodeIntegerForKey:@"lifeLong"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
