//
//  MKBLEDeviceModel.h
//  mkcooling
//
//  Created by mist on 2020/6/9.
//  Copyright © 2020 mist. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBLEDeviceModel : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, copy, readonly) NSString *pId;

@property (nonatomic, copy, readonly) NSString *mac;

@property (nonatomic, assign) NSInteger lifeLong;

@property (nonatomic, copy) NSString *UUIDString;

- (instancetype)initWithManufactureData:(NSData *)manufactureData andUUIDString:(NSString *)UUIDString;

@end

NS_ASSUME_NONNULL_END
