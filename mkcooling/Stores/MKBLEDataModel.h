//
//  MKBLEDataModel.h
//  mkcooling
//
//  Created by mist on 2019/10/6.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBLEDataModel : NSObject<NSCoding>

@property (nonatomic, assign) NSInteger temp_int;

@property (nonatomic, assign) NSInteger temp_dec;

@property (nonatomic, assign) NSInteger ir_tempo_int;

@property (nonatomic, assign) NSInteger ir_tempo_dec;

@property (nonatomic, assign) NSInteger ir_tempa_int;

@property (nonatomic, assign) NSInteger ir_tempa_dec;

@property (nonatomic, assign) NSInteger fan_rpm;

@property (nonatomic, assign) NSInteger fan_percentage;

@property (nonatomic, assign) NSInteger ir_switch;

@property (nonatomic, assign) NSInteger auth_key;

- (void)setDataModelWithRawData:(NSData *)rawData;

@end

NS_ASSUME_NONNULL_END
