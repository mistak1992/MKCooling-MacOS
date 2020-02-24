//
//  MKConvertor.m
//  mkcooling
//
//  Created by mist on 2019/10/6.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import "MKConvertor.h"

@implementation MKConvertor

+ (NSString *)stringWithHexNumber:(NSUInteger)hexNumber{
    char hexChar[6];
    sprintf(hexChar, "%x", (int)hexNumber);
    NSString *hexString = [NSString stringWithCString:hexChar encoding:NSUTF8StringEncoding];
    return hexString;
}

+ (NSInteger)numberWithHexString:(NSString *)hexString{
    const char *hexChar = [hexString cStringUsingEncoding:NSUTF8StringEncoding];
    int hexNumber;
    sscanf(hexChar, "%x", &hexNumber);
    return (NSInteger)hexNumber;
}

@end
