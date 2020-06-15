//
//  MKBLEProtocolModel.h
//  mkcooling
//
//  Created by mist on 2020/6/9.
//  Copyright © 2020 mist. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBLEProtocolModel : NSObject

@property (nonatomic, assign) MKBLEProtocolHdr hdr;

@property (nonatomic, assign) MKBLEProtocolType typ;

@property (nonatomic, assign) NSInteger len;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) NSData *token;

@property (nonatomic, strong) NSData *pck;

@property (nonatomic, assign) NSInteger bat;

@property (nonatomic, assign) MKBLEProtocolRet ret;

@property (nonatomic, strong) NSData *hvr;

@property (nonatomic, strong) NSData *svr;

@end

@interface MKBLEProtocolTool : NSObject

+ (void)setCurrentToken:(nullable NSData *)token;

+ (nullable NSData *)getCurrentToken;

+ (MKBLEProtocolModel *)decodeProtocolWithRawData:(NSData *)rawData;

+ (NSData *)encodeProtocolWithModel:(MKBLEProtocolModel *)model;

+ (NSData *)encodeProtocolForAction:(MKBLEAction)action withModel:(MKBLEProtocolModel * _Nullable)model;

@end

NS_ASSUME_NONNULL_END
