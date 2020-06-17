//
//  MKBLEProtocolModel.m
//  mkcooling
//
//  Created by mist on 2020/6/9.
//  Copyright © 2020 mist. All rights reserved.
//

#import "MKBLEProtocolModel.h"

#import "MKConvertor.h"

static NSData *currentToken;

@implementation MKBLEProtocolModel

- (NSString *)description{
    return [NSString stringWithFormat:@"\nhdr:%zd\ntyp:%zd\nlen:%zd\ndata:%@\ntoken:%@\npck:%@\nbat:%zd\nret:%zd\nhvr:%@\nsvr:%@", self.hdr, self.typ, self.len, self.data, self.token, self.pck, self.bat, self.ret, self.hvr, self.svr];
}

@end

@implementation MKBLEProtocolTool

+ (void)setCurrentToken:(nullable NSData *)token{
    currentToken = token;
}

+ (nullable NSData *)getCurrentToken{
    return currentToken;
}

+ (MKBLEProtocolModel *)decodeProtocolWithRawData:(NSData *)rawData{
    MKBLEProtocolModel *model = [MKBLEProtocolModel new];
//    NSData *data = [MKCryptoTools AES128DecryptData:rawData key:[MKCryptoTools dataForHexString:@"E452B0D58FA946639B422393FF2AA5B4"]];
    NSData *data = rawData;
    model.hdr = [MKConvertor numberWithUnsignData:[data subdataWithRange:NSMakeRange(0, 1)]];
    model.typ = [MKConvertor numberWithUnsignData:[data subdataWithRange:NSMakeRange(1, 1)]];
    model.len = [MKConvertor numberWithUnsignData:[data subdataWithRange:NSMakeRange(2, 1)]];
    model.data = [data subdataWithRange:NSMakeRange(3, model.len)];
    switch (model.typ) {
        case MKBLEProtocolTypeGetToken:{
            model.token = model.data;
            model.pck = [data subdataWithRange:NSMakeRange(3 + model.len, 1)];
            break;
        }
        case MKBLEProtocolTypeFetchInfo:{
            model.ret = [[MKConvertor hexStringFromData:model.data] integerValue];
            break;
        }
        case MKBLEProtocolTypeSetFanDuty:{
            model.bat = [[MKConvertor hexStringFromData:model.data] integerValue];
            break;
        }
        case MKBLEProtocolTypeSetDelay:{
            model.ret = [[MKConvertor hexStringFromData:model.data] integerValue];
            break;
        }
        case MKBLEProtocolTypeResponse:{
            model.ret = [[MKConvertor hexStringFromData:model.data] integerValue];
            break;
        }
        default:
            //MKBLEProtocolTypeOTA
            break;
    }
    return model;
}

+ (NSData *)encodeProtocolWithModel:(MKBLEProtocolModel *)model{
    NSMutableData *composeDatas = [NSMutableData new];
    switch (model.hdr) {
        case MKBLEProtocolHdrTypeSend:{
            [composeDatas appendData:[MKConvertor dataForHexString:@"01"]];
            break;
        }
        case MKBLEProtocolHdrTypeRecived:{
            [composeDatas appendData:[MKConvertor dataForHexString:@"10"]];
            break;
        }
        default:
            break;
    }
    switch (model.typ) {
        default:{
            [composeDatas appendData:[MKConvertor dataForHexString:[NSString stringWithFormat:@"%02zd", model.typ]]];
            break;
        }
    }
    [composeDatas appendData:[MKConvertor dataForHexString:[NSString stringWithFormat:@"%02zd", model.data.length]]];
    [composeDatas appendData:model.data];
    [composeDatas appendData:model.token];
    [composeDatas appendData:model.pck];
    for (NSUInteger i = [composeDatas length]; i < 16; ++i) {
        uint8_t byte = arc4random_uniform(255);
        [composeDatas appendBytes:&byte length:sizeof(byte)];
    }
//    NSData *keyk = [MKConvertor dataForHexString:@"E452B0D58FA946639B422393FF2AA5B4"];
//    NSData *rawData = [MKConvertor AES128EncryptData:composeDatas key:keyk];// [MKCryptoTools dataForHexString:@"475301002D1A683D48271A18316E471A"]
//    NSLog(@"原文:%@ 密钥:%@, 密文:%@", composeDatas, keyk, rawData);
    NSData *rawData = composeDatas;
    return rawData;
}

+ (NSData *)encodeProtocolForAction:(MKBLEAction)action withModel:(MKBLEProtocolModel * _Nullable)model{
    if (model == nil) {
        model = [MKBLEProtocolModel new];
    }
    model.hdr = MKBLEProtocolHdrTypeSend;
    model.token = currentToken;
    model.pck = [NSData new];
    if (model.token == nil) {
        model.token = [NSData new];
    }
    if (model.pck == nil) {
        model.pck = [NSData new];
    }
    switch (action) {
        case MKBLEActionGetToken:{
            model.typ = MKBLEProtocolTypeGetToken;
            model.data = [NSData new];
            break;
        }
        case MKBLEActionFetchInfo:{
            model.typ = MKBLEActionFetchInfo;
            break;
        }
        case MKBLEActionSetFanDuty:{
            model.typ = MKBLEActionSetFanDuty;
            break;
        }
        case MKBLEActionSetDelay:{
            model.typ = MKBLEActionSetDelay;
            break;
        }
        default:
            break;
    }
    return [MKBLEProtocolTool encodeProtocolWithModel:model];
}


@end
