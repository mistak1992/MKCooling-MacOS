//
//  MKDataController.h
//  mkcooling
//
//  Created by mist on 2019/10/19.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKDataController : NSObject

+ (instancetype)sharedSingleton;

- (NSArray *)getRecentDatasWithNumber:(int)number;

- (MKBLEDataModel *)getBLEModel;

- (BOOL)saveBLEModel:(MKBLEDataModel *)model;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (id)copy NS_UNAVAILABLE;

- (id)mutableCopy NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
