//
//  MKBLEManager.m
//  MKCooling
//
//  Created by mist on 2019/9/16.
//  Copyright © 2019 mist. All rights reserved.
//

#import "MKBLEManager.h"

#import <IOBluetooth/IOBluetooth.h>

#import "MKConvertor.h"

#import "MKBLEProtocolModel.h"

#define lifeLong 2 // 比目标设备数+1
// 单次操作
dispatch_semaphore_t semaphore;

static NSTimeInterval sendCommandTimeoutInterval = 6;

static NSTimeInterval connectingTimeoutInterval = 12;

static MKBLEManager *mgr = nil;

@interface MKBLEGeneralModel : NSObject

@property (nonatomic, strong) id model;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, copy) NSString *deviceMac;

@property (nonatomic, assign) NSInteger lifeLongRecord;

@end

@interface MKBLEManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, assign) BOOL centralFlag;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSMutableArray *schindlerList;

@property (nonatomic, strong) MKBLEGeneralModel *connectingDevice;

//@property (nonatomic, strong) CBCharacteristic *currentCharacteristic;
//
//@property (nonatomic, assign) NSInteger currentValue;
//
//@property (nonatomic, strong) CBService *service;

@property (nonatomic, assign) MKBLEAction action;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timerCounterOfSendCommand;

@property (nonatomic, assign) NSInteger timerCounterOfConnecting;

@property (nonatomic, assign) BOOL isSendCommandTimeoutOn;

@property (nonatomic, assign) BOOL isConnectingTimeoutOn;

@end

@implementation MKBLEManager

+ (instancetype)sharedSingleton{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 要使用self来调用
        mgr = [[self alloc] init];
    });
    return mgr;
}

- (instancetype)init{
    if (self = [super init]) {
        semaphore = dispatch_semaphore_create(1);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        [self initData];
    }
    return self;
}

- (void)setState:(MKBLEState)state{
    _state = state;
    DDLogVerbose(@"状态写入为:%ld", state);
}

- (NSTimer *)timer{
    if (_timer == nil) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

- (void)timerAction:(NSTimer *)timer{
    if (self.timerCounterOfConnecting == 0) {
        [self stop];
    }else{
        if (_isConnectingTimeoutOn == YES) {
            self.timerCounterOfConnecting--;
            DDLogVerbose(@"超时倒数:%ld", self.timerCounterOfConnecting);
        }
    }
    if (self.timerCounterOfSendCommand == 0) {
        [self actionForEndCommunication];
    }else{
        if (_isSendCommandTimeoutOn == YES) {
            self.timerCounterOfSendCommand--;
        }
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (@available(macOS 10.13, *)) {
        _centralFlag = (central.state == CBManagerStatePoweredOn);
    } else {
        
    }
    if (self.state >= MKBLEStatePoweredOn && central.state == CBManagerStatePoweredOn) {
        return;
    }
    self.state = (MKBLEState)central.state;
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:(MKBLEState)central.state];
    }
}

- (void)start{
    if (_centralFlag == YES) {
        // load connected device
        NSArray *storedDevices = [self loadSavedDevices];
        if ([storedDevices isKindOfClass:[NSArray class]] == YES && storedDevices.count > 0) {
            for (MKBLEDeviceModel *device in storedDevices) {
                if (![device isKindOfClass:[MKBLEDeviceModel class]]) continue;
                NSArray<CBPeripheral *> *deviceArr = [_centralManager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:[[NSUUID alloc] initWithUUIDString:device.UUIDString]]];
                MKBLEGeneralModel *gModel = [MKBLEGeneralModel new];
                gModel.model = device;
                gModel.deviceMac = device.mac;
                gModel.peripheral = deviceArr.firstObject;
                self.connectingDevice = gModel;
                if (self.connectingDevice.peripheral != nil) {
                    // connecting
                    // discover device callback
                    for (NSString *mac in _whiteList) {
                        if ([mac isEqualToString:device.mac] == YES) {
                            [self arrangeDiscoveredDeviceModel:device andPeripheral:self.connectingDevice.peripheral];
                        }
                    }
//                    self.state = MKBLEStateConnecting;
//                    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
//                        [self.delegate manager:self didUpdateState:MKBLEStateConnecting];
//                    }
//                    [self.centralManager connectPeripheral:self.connectingDevice.peripheral options:@{}];
//                    self.isConnectingTimeoutOn = YES;
                    return;
                }else{
                    
                }
            }
        }else{
            //no device
            //Device Information 0x180A
            [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@false}];
            self.isConnectingTimeoutOn = YES;
            self.state = MKBLEStateScanning;
            if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
                [self.delegate manager:self didUpdateState:MKBLEStateScanning];
            }
            //        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180D"]] options:nil];
        }
    }
    
}

- (void)stop{
    self.timerCounterOfConnecting = connectingTimeoutInterval;
    self.isConnectingTimeoutOn = NO;
    [_centralManager stopScan];
    _discoveredDevices = @[];
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    if (self.state > MKBLEStatePoweredOn) {
        self.state = MKBLEStatePoweredOn;
        if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
            [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
//    DDLogVerbose(@"%@ %@", peripheral, advertisementData);
    NSData *manufacturerData = advertisementData[@"kCBAdvDataManufacturerData"];
    NSString *manufaceturerHexStr = [[MKConvertor hexStringFromData:manufacturerData] lowercaseString];
    if ([manufaceturerHexStr length] > 8 && [[manufaceturerHexStr substringWithRange:NSMakeRange(0, 8)] isEqualToString:@"4d4b0001"] == YES) {
        DDLogVerbose(@"广播数据:%@", advertisementData);
//        self.peripheral = peripheral;
//        [self.centralManager connectPeripheral:peripheral options:@{}];
//        self.state = MKBLEStateConnecting;
//        if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
//            [self.delegate manager:self didUpdateState:MKBLEStateConnecting];
//        }
        MKBLEDeviceModel *model = [[MKBLEDeviceModel alloc] initWithManufactureData:manufacturerData andUUIDString:peripheral.identifier.UUIDString];
        // 获取big endian比较
        NSMutableData *macDatas = [MKConvertor dataForHexString:model.mac].mutableCopy;
//        int32_t *bytes = macDatas.mutableBytes;
//        *bytes = CFSwapInt32(*bytes);
        NSString *macReverse = [[MKConvertor hexStringFromData:macDatas] lowercaseString];
        // 判断是不是白名单
        for (NSString *mac in _whiteList) {
            if ([mac isEqualToString:macReverse] == YES) {
                [self arrangeDiscoveredDeviceModel:model andPeripheral:peripheral];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.centralManager stopScan];
    self.isConnectingTimeoutOn = NO;
    self.timerCounterOfConnecting = connectingTimeoutInterval;
#warning 没改完
    if (self.connectingDevice.peripheral == nil) {
//        self.connectingDevice
        self.connectingDevice.peripheral = peripheral;
    }
    self.connectingDevice.peripheral.delegate = self;
    [peripheral discoverServices:@[]];
    self.state = MKBLEStateConnected;
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStateConnected];
    }
//    if (@available(macOS 10.13, *)) {
//
//    } else {
//        // Fallback on earlier versions
//    }
    [self addSavedDevice:self.connectingDevice.model];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
//    //重新开始
//    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@false}];
    self.connectingDevice = nil;
    self.state = MKBLEStatePoweredOn;
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
    }
//    [self.timer setFireDate:[NSDate distantPast]];
//    self.timerCounter = connectionTimeoutInterval;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    DDLogDebug(@"Connect Failed");
    self.connectingDevice = nil;
    self.state = MKBLEStatePoweredOn;
    if ([self.delegate respondsToSelector:@selector(manager:result:ofDeviceModel:forFunction:withResponseData:)] == YES) {
        [self.delegate manager:self result:MKBLEResultFail ofDeviceModel:self.connectingDevice.model forFunction:(MKBLEFunction)self.action withResponseData:nil];
    }
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    DDLogVerbose(@"%@", peripheral);
//    for (CBService *service in peripheral.services) {
//        self.service = service;
//        [peripheral discoverCharacteristics:[self getAllCharacteristicUUID] forService:service];
//    }
    for (CBService *service in peripheral.services) {
        if ([[service.UUID.UUIDString uppercaseString] containsString:@"1890"] == YES) {
            [peripheral discoverCharacteristics:@[] forService:service];
            return;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([[characteristic.UUID.UUIDString uppercaseString] containsString:@"1891"] == YES) {
    //            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            if (self.action != MKBLEActionNone) {
                //request data
                NSDictionary *userInfo = nil;
                if ([self.delegate respondsToSelector:@selector(manager:userInfoForFuntion:)] == YES) {
                    userInfo = [self.delegate manager:mgr userInfoForFuntion:(MKBLEFunction)self.action];
                }
                MKBLEProtocolModel *model = [MKBLEProtocolModel new];
                switch (self.action) {
                    case MKBLEActionGetToken:{
                        break;
                    }
                    case MKBLEActionFetchInfo:{
                        break;
                    }
                    case MKBLEActionSetFanDuty:{
                        if (userInfo != nil && [[userInfo allKeys] containsObject:@"fanDuty"] == YES) {
                            uint8_t fan_duty = (uint8_t)[userInfo[@"fanDuty"] intValue];
                            model.data = [NSData dataWithBytes:&fan_duty length:sizeof(fan_duty)];
                        }
                        break;
                    }
                    case MKBLEActionSetDelay:{
                        break;
                    }
                    case MKBLEActionSetSwitch:{
                        break;
                    }
                    default:
                        break;
                }
                //send data
                [peripheral writeValue:[MKBLEProtocolTool encodeProtocolForAction:self.action withModel:model] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }else{
                [peripheral writeValue:[MKBLEProtocolTool encodeProtocolForAction:MKBLEActionFetchInfo withModel:nil] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    }
    if (error != nil) {
        //NSLog(@"%@", error);
        self.state = MKBLEStatePoweredOn;
        if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
            [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error != nil) {
        //DDLogInfo(@"%@", error);
        self.state = MKBLEStatePoweredOn;
        if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
            [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
        }
        return;
    }
//    DDLogInfo(@"response:%@ uuid:%@", characteristic.value, characteristic.UUID);
//    uint8 i;
//    [characteristic.value getBytes:&i length:sizeof(i)];
    // 更新本地Model
//    if ([self.delegate respondsToSelector:@selector(manager:didUpdateValue:forIndex:)] == YES) {
//        [self.delegate manager:mgr didUpdateValue:i forIndex:[MKConvertor numberWithHexString:characteristic.UUID.UUIDString]];
//    }
    [self actionForCharacteristic:characteristic value:characteristic.value];
    NSLog(@"上传完成");
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error != nil) {
        //DDLogError(@"%@", error);
        self.state = MKBLEStatePoweredOn;
        if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
            [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
        }
        return;
    }
    // 收到回复
    [self actionForCharacteristic:characteristic value:characteristic.value];
    NSLog(@"读取完成");
}

- (void)addSavedDevice:(MKBLEDeviceModel *)deviceModel{
//    NSArray *storedDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
//    NSMutableArray *newDevices = nil;
//    if (![storedDevices isKindOfClass:[NSArray class]]) {
//        DDLogError(@"Can't find/create an array to store the uuid");
//    }
//    newDevices = [NSMutableArray arrayWithArray:storedDevices];
//    if (uuid) {
//        [newDevices removeAllObjects];
//        [newDevices addObject:uuid.UUIDString];
//    }
//    /* Store */
//    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([self.datasource respondsToSelector:@selector(manager:persistPeripheralWithDeviceModel:)] == YES) {
        [self.datasource manager:mgr persistPeripheralWithDeviceModel:deviceModel];
    }
}

- (NSArray<MKBLEDeviceModel*>*)loadSavedDevices{
//    NSArray *storedDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSArray<MKBLEDeviceModel *> *storedDevices = nil;
    if ([self.datasource respondsToSelector:@selector(retrievePeripheralsWithDeviceModelsForManager:)] == YES) {
        storedDevices = [self.datasource retrievePeripheralsWithDeviceModelsForManager:mgr];
    }
    return storedDevices;
}

- (void)initData{
    _whiteList = [NSMutableArray array];
    _schindlerList = [NSMutableArray array];
    _timerCounterOfConnecting = connectingTimeoutInterval;
    _timerCounterOfSendCommand = sendCommandTimeoutInterval;
}

- (void)resetConnection{
    /* Store */
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)arrangeDiscoveredDeviceModel:(MKBLEDeviceModel *)model andPeripheral:(CBPeripheral *)peripheral{
    if ([_whiteList containsObject:model.mac] == YES) {
        NSMutableArray *discoveredArray = [NSMutableArray array];
        MKBLEGeneralModel *gModel = [[MKBLEGeneralModel alloc] init];
        gModel.model = model;
        gModel.peripheral = peripheral;
        // 不能有重复的被害人
        if ([self.schindlerList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"model.mac = %@", model.mac]].count == 0) {
            [self.schindlerList addObject:gModel];
        }
        // 扣血过程
        [self.schindlerList enumerateObjectsUsingBlock:^(MKBLEGeneralModel *m, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[m.model mac] isEqualToString:model.mac] == YES) {
                m.lifeLongRecord = lifeLong;
            }
            m.lifeLongRecord--;
            if (m.lifeLongRecord == 0) {
                [self.schindlerList removeObject:m];
                DDLogInfo(@"Dead man");
            }else{
                [discoveredArray addObject:m.model];
            }
        }];
        _discoveredDevices = discoveredArray.copy;
        if ([self.delegate respondsToSelector:@selector(manager:didDiscoveredDevices:)] == YES) {
            [self.delegate manager:self didDiscoveredDevices:_discoveredDevices];
        }
    }
}

- (MKBLEResult)setDevice:(MKBLEDeviceModel *)deviceModel forFunction:(MKBLEFunction)function{
    if (_state == MKBLEStateConnecting) {
        return MKBLEResultBusy;
    }
    //NSLog(@"开锁操作");
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSArray *temp = [self.schindlerList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"model.mac = %@", deviceModel.mac]];
    MKBLEGeneralModel *gModel = [temp firstObject];
    self.connectingDevice = gModel;
    //NSLog(@"要连接的设备:%@", self.connectingDevice);
    if (self.connectingDevice.peripheral.state == CBPeripheralStateConnected) {
        self.state = MKBLEStateConnected;
    }else{
        self.state = MKBLEStateConnecting;
    }
    switch (function) {
        case MKBLEFunctionSetFanDuty:
            self.action = MKBLEActionSetFanDuty;
            break;
        case MKBLEFunctionFetchInfo:
            self.action = MKBLEActionFetchInfo;
            break;
        case MKBLEFunctionSetDelay:
            self.action = MKBLEActionSetDelay;
            break;
        case MKBLEFunctionSetSwitch:
            self.action = MKBLEActionSetSwitch;
            break;
        default:
            self.action = MKBLEActionFetchInfo;
            break;
    }
    dispatch_semaphore_signal(semaphore);
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:_state];
    }
    [self actionForBeginCommunication];
    if (_state == MKBLEStateConnected) {
        [self.connectingDevice.peripheral discoverServices:@[]];
    }else{
        [_centralManager connectPeripheral:gModel.peripheral options:nil];
    }
    return MKBLEResultSending;
}

- (void)actionForCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)rawValue{
    [self actionForTimeoutOff];
    if (rawValue.length != 16) {
        return;
    }
    MKBLEProtocolModel *m = [MKBLEProtocolTool decodeProtocolWithRawData:rawValue];
    //NSLog(@"\n%@\n%@", rawValue, m.description);
    switch (m.typ) {
        case MKBLEProtocolTypeGetToken:{
            //NSLog(@"获取Token成功");
//            self.token = m.token.copy;
            [MKBLEProtocolTool setCurrentToken:m.token.copy];
//            self.pck = m.pck;
            // 链接成功继续干活
            if (self.connectingDevice.peripheral.state == CBPeripheralStateConnected) {
                [self actionForTimeoutOn];
                // 可以根据action来区分操作, 但这里没必要
                [self.connectingDevice.peripheral writeValue:[MKBLEProtocolTool encodeProtocolForAction:self.action withModel:nil] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }else{
                if (self.state >= MKBLEStateScanning) {
                    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
                        [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
                    }
                }
                if ([self.delegate respondsToSelector:@selector(manager:result:ofDeviceModel:forFunction:withResponseData:)] == YES) {
                    [self.delegate manager:self result:MKBLEResultFail ofDeviceModel:self.connectingDevice.model forFunction:(MKBLEFunction)self.action withResponseData:nil];
                }
                [self disconnectAction];
            }
            break;
        }
        case MKBLEProtocolTypeResponse:{
            //NSLog(@"开门成功");
            if ([self.delegate respondsToSelector:@selector(manager:result:ofDeviceModel:forFunction:withResponseData:)] == YES) {
                [self.delegate manager:self result:MKBLEResultSuccess ofDeviceModel:self.connectingDevice.model forFunction:(MKBLEFunction)self.action withResponseData:m.data];
            }
            [self disconnectAction];
            break;
        }
        case MKBLEProtocolTypeFetchInfo:{
            //NSLog(@"关门成功");
            if ([self.delegate respondsToSelector:@selector(manager:result:ofDeviceModel:forFunction:withResponseData:)] == YES) {
                [self.delegate manager:self result:MKBLEResultSuccess ofDeviceModel:self.connectingDevice.model forFunction:(MKBLEFunction)self.action withResponseData:nil];
            }
            [self disconnectAction];
            break;
        }
        default:{
            self.state = MKBLEStateConnected;
            if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
                [self.delegate manager:self didUpdateState:MKBLEStateConnected];
            }
            break;
        }
    }
}

- (void)disconnectAction{
    //NSLog(@"手动断开");
    if (self.isNeedDisconnectAfterCommunication == YES) {
        [MKBLEProtocolTool setCurrentToken:nil];
        [self.centralManager cancelPeripheralConnection:self.connectingDevice.peripheral];
    }
}

- (void)actionForEndCommunication{
    [self actionForTimeoutOff];
    if (self.isNeedDisconnectAfterCommunication == YES) {
        if (self.connectingDevice != nil && self.connectingDevice.peripheral != nil) {
            //NSLog(@"断开连接");
            [_centralManager cancelPeripheralConnection:self.connectingDevice.peripheral];
        }
        self.connectingDevice = nil;
    }
    if ([self.delegate respondsToSelector:@selector(manager:result:ofDeviceModel:forFunction:withResponseData:)] == YES) {
        [self.delegate manager:self result:MKBLEResultFail ofDeviceModel:self.connectingDevice.model forFunction:(MKBLEFunction)self.action withResponseData:nil];
    }
}

- (void)actionForBeginCommunication{
    [self actionForTimeoutOn];
}

- (void)actionForTimeoutOff{
    // 超时计时器停止工作
//    [self.timer setFireDate:[NSDate distantFuture]];
    self.isSendCommandTimeoutOn = NO;
    self.timerCounterOfSendCommand = sendCommandTimeoutInterval;
}

- (void)actionForTimeoutOn{
    // 超时计时器工作
//    self.timerCounter = connectionTimeoutInterval;
//    [self.timer setFireDate:[NSDate distantPast]];
    self.isSendCommandTimeoutOn = YES;
}

@end

@implementation MKBLEGeneralModel

- (instancetype)init{
    if (self = [super init]) {
        self.lifeLongRecord = lifeLong;
    }
    return self;
}

@end
