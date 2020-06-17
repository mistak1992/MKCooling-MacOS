//
//  MKConvertor.h
//  mkcooling
//
//  Created by mist on 2019/10/6.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKConvertor : NSObject

+ (NSString *)hexStringFromData:(NSData *)data;

+ (NSData*)dataForHexString:(NSString *)hexString;

+ (NSString *)stringWithHexNumber:(NSUInteger)hexNumber stringLen:(NSInteger)len;

+ (NSInteger)numberWithHexString:(NSString *)hexString;

+ (NSUInteger)numberWithUnsignData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
