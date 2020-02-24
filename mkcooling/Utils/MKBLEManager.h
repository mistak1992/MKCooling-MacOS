//
//  MKBLEManager.h
//  MKCooling
//
//  Created by mist on 2019/9/16.
//  Copyright © 2019 mist. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MKC_UUID_IDX) {
    MKC_UUID_IDX_SV = 10896,
    MKC_UUID_IDX_TEMP_INT,
    MKC_UUID_IDX_TEMP_DEC,
    MKC_UUID_IDX_IR_TEMPO_INT,
    MKC_UUID_IDX_IR_TEMPO_DEC,
    MKC_UUID_IDX_IR_TEMPA_INT,
    MKC_UUID_IDX_IR_TEMPA_DEC,
    MKC_UUID_IDX_FAN_RPM,
    MKC_UUID_IDX_FAN_PERCENTAGE,
    MKC_UUID_IDX_IR_SWITCH,
    MKC_UUID_IDX_AUTH_KEY,
    MKC_UUID_IDX_NB
};

typedef NS_ENUM(NSUInteger, MKBLEState) {
    MKBLEStateUnknown = 0,
    MKBLEStateResetting,
    MKBLEStateUnsupported,
    MKBLEStateeUnauthorized,
    MKBLEStatePoweredOff,
    MKBLEStatePoweredOn,
    MKBLEStateConnected,
    MKBLEStateStandby,
};

@class MKBLEManager;

@protocol MKBLEManagerDelegate <NSObject>

- (void)manager:(MKBLEManager *)manager didUpdateState:(MKBLEState)state;

- (void)manager:(MKBLEManager *)manager didUpdateValue:(NSInteger)value forIndex:(MKC_UUID_IDX)index;

@end

@interface MKBLEManager : NSObject

@property (nonatomic, weak) id<MKBLEManagerDelegate> delegate;

@property (nonatomic, assign) NSInteger interval;

+ (instancetype)sharedSingleton;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (id)copy NS_UNAVAILABLE;

- (id)mutableCopy NS_UNAVAILABLE;

- (void)start;

- (void)stop;

- (void)setDataAtIdx:(MKC_UUID_IDX)uuid_idx value:(NSInteger)value;

- (void)getDataAtIdx:(MKC_UUID_IDX)uuid_idx;

- (void)getDatas;

- (void)resetConnection;

@end

NS_ASSUME_NONNULL_END
