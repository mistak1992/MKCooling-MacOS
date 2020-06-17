//
//  MKBLEDataModel.m
//  mkcooling
//
//  Created by mist on 2019/10/6.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import "MKBLEDataModel.h"

#import "MKConvertor.h"

@implementation MKBLEDataModel

//将对象编码(即:序列化)
- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeInteger:_temp_int forKey:@"temp_int"];
    [coder encodeInteger:_temp_dec forKey:@"temp_dec"];
    [coder encodeInteger:_ir_tempo_int forKey:@"ir_tempo_int"];
    [coder encodeInteger:_ir_tempo_dec forKey:@"ir_tempo_dec"];
    [coder encodeInteger:_ir_tempa_int forKey:@"ir_tempa_int"];
    [coder encodeInteger:_ir_tempa_dec forKey:@"ir_tempa_dec"];
    [coder encodeInteger:_fan_rpm forKey:@"fan_rpm"];
    [coder encodeInteger:_fan_percentage forKey:@"fan_percentage"];
    [coder encodeInteger:_ir_switch forKey:@"ir_switch"];
    [coder encodeInteger:_auth_key forKey:@"auth_key"];
    [coder encodeObject:_update_time forKey:@"update_time"];
}

//将对象解码(反序列化)
- (nullable instancetype)initWithCoder:(NSCoder *)coder{
    if (self = [super init]){
        self.temp_int = [coder decodeIntegerForKey:@"temp_int"];
        self.temp_dec = [coder decodeIntegerForKey:@"temp_dec"];
        self.ir_tempo_int = [coder decodeIntegerForKey:@"ir_tempo_int"];
        self.ir_tempo_dec = [coder decodeIntegerForKey:@"ir_tempo_dec"];
        self.ir_tempa_int = [coder decodeIntegerForKey:@"ir_tempa_int"];
        self.ir_tempa_dec = [coder decodeIntegerForKey:@"ir_tempa_dec"];
        self.fan_rpm = [coder decodeIntegerForKey:@"fan_rpm"];
        self.fan_percentage = [coder decodeIntegerForKey:@"fan_percentage"];
        self.ir_switch = [coder decodeIntegerForKey:@"ir_switch"];
        self.auth_key = [coder decodeIntegerForKey:@"auth_key"];
        self.update_time = [coder decodeObjectForKey:@"update_time"];
    }
    return (self);
}

- (void)setDataModelWithRawData:(NSData *)rawData{
    if (rawData.length == 8) {
        self.ir_tempo_int = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(0, 1)]];
        self.ir_tempo_dec = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(1, 1)]];
        self.ir_tempa_int = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(2, 1)]];
        self.ir_tempa_dec = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(3, 1)]];
        self.fan_percentage = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(4, 1)]];
        self.fan_rpm = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(5, 2)]];
        self.delay = [MKConvertor numberWithUnsignData:[rawData subdataWithRange:NSMakeRange(7, 1)]];
        self.ir_switch = 0;
        self.update_time = [MKDate date];
    }
}

@end
