//
//  MKBLEManager.h
//  MKCooling
//
//  Created by mist on 2019/9/16.
//  Copyright © 2019 mist. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

#import "MKBLEDeviceModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MKC_UUID_IDX) {
    MKC_UUID_IDX_SV = 6288,
    MKC_UUID_IDX_WRITE_IN,
    MKC_UUID_IDX_NB
};

typedef NS_ENUM(NSUInteger, MKBLEState) {
    MKBLEStateUnknown = 0,
    MKBLEStateResetting,
    MKBLEStateUnsupported,
    MKBLEStateeUnauthorized,
    MKBLEStatePoweredOff,
    MKBLEStatePoweredOn,
    MKBLEStateScanning,
    MKBLEStateConnecting,
    MKBLEStateConnected,
    MKBLEStateCommucating,
};

@class MKBLEManager;

@protocol MKBLEManagerDelegate <NSObject>

- (void)manager:(MKBLEManager *)manager didUpdateState:(MKBLEState)state;

- (void)manager:(MKBLEManager *)manager didDiscoveredDevices:(NSArray<MKBLEDeviceModel *> *)devices;

- (void)manager:(MKBLEManager *)manager result:(MKBLEResult)result ofDeviceModel:(MKBLEDeviceModel *)deviceModel forFunction:(MKBLEFunction)function withResponseData:(nullable NSData *)data;

- (NSDictionary *)manager:(MKBLEManager *)manager userInfoForFuntion:(MKBLEFunction)function;

@end

@protocol MKBLEManagerDatasource <NSObject>

- (NSArray<MKBLEDeviceModel *> *)retrievePeripheralsWithDeviceModelsForManager:(MKBLEManager *)manager;

- (void)manager:(MKBLEManager *)manager persistPeripheralWithDeviceModel:(MKBLEDeviceModel *)deviceModel;

@end

@interface MKBLEManager : NSObject

@property (nonatomic, weak) id<MKBLEManagerDelegate> delegate;

@property (nonatomic, weak) id<MKBLEManagerDatasource> datasource;

@property (nonatomic, assign) NSInteger interval;

@property (nonatomic, assign) MKBLEState state;

@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *whiteList;

@property (nonatomic, strong, readonly) NSArray<MKBLEDeviceModel *> *discoveredDevices;

@property (nonatomic, assign) BOOL isNeedDisconnectAfterCommunication;

+ (instancetype)sharedSingleton;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (id)copy NS_UNAVAILABLE;

- (id)mutableCopy NS_UNAVAILABLE;

- (void)start;

- (void)stop;

- (MKBLEResult)setDevice:(MKBLEDeviceModel *)deviceModel forFunction:(MKBLEFunction)function;

- (void)resetConnection;

@end

NS_ASSUME_NONNULL_END
