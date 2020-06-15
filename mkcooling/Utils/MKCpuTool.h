//
//  MKCpuTool.h
//  mkcooling
//
//  Created by mist on 2020/3/19.
//  Copyright © 2020 mist. All rights reserved.
//

#import <Foundation/Foundation.h>

#define arrayLength 5

NS_ASSUME_NONNULL_BEGIN

@interface MKCpuTool : NSObject

+ (NSArray *)getCPULoadTotal;

+ (double)getCPULoadAvg;

+ (double)getCPULoadMax;

+ (double)getCPULoadByCoreIndex:(unsigned int)coreIndex;

+ (instancetype)sharedSingleton;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (id)copy NS_UNAVAILABLE;

- (id)mutableCopy NS_UNAVAILABLE;

- (NSArray *)getCPULoadRecords;

@end

NS_ASSUME_NONNULL_END
