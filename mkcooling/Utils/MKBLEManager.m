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

//#import "MKBLEDataModel.h"

static NSTimeInterval connectionTimeoutInterval = 12;

static MKBLEManager *mgr = nil;

@interface MKBLEManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, assign) BOOL centralFlag;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) CBCharacteristic *currentCharacteristic;

@property (nonatomic, assign) NSInteger currentValue;

@property (nonatomic, strong) CBService *service;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timerCounter;

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
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        [self loadData];
    }
    return self;
}

- (NSTimer *)timer{
    if (_timer == nil) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

- (void)timerAction:(NSTimer *)timer{
    if (self.timerCounter == 0) {
        [self stop];
    }else{
        self.timerCounter--;
        DDLogVerbose(@"超时倒数:%ld", self.timerCounter);
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (@available(macOS 10.13, *)) {
        _centralFlag = (central.state == CBManagerStatePoweredOn);
    } else {
        
    }
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:central.state];
    }
}

- (void)start{
    if (_centralFlag == YES && [self loadSavedDevices] == NO) {
        //Device Information 0x180A
        [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@false}];
        self.timerCounter = connectionTimeoutInterval;
        [self.timer setFireDate:[NSDate distantPast]];
//        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180D"]] options:nil];
    }
}

- (void)stop{
    [self.timer setFireDate:[NSDate distantFuture]];
    self.timerCounter = 0;
    [_centralManager stopScan];
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
//    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
//        [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
//    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    DDLogVerbose(@"%@", peripheral);
    if ([peripheral.name isEqualToString:@"MKCooling"]) {
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:peripheral options:@{}];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.centralManager stopScan];
    [self.timer setFireDate:[NSDate distantFuture]];
    self.timerCounter = 0;
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"1890"]]];
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStateConnected];
    }
    if (@available(macOS 10.13, *)) {
        [self addSavedDevice:peripheral.identifier];
    } else {
        // Fallback on earlier versions
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //重新开始
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@false}];
    [self.timer setFireDate:[NSDate distantPast]];
    self.timerCounter = connectionTimeoutInterval;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    DDLogDebug(@"Connect Failed");
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStatePoweredOn];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    DDLogVerbose(@"%@", peripheral);
    for (CBService *service in peripheral.services) {
        self.service = service;
        [peripheral discoverCharacteristics:[self getAllCharacteristicUUID] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic properties] != 0) {
            if (_currentValue != NSIntegerMax && _currentCharacteristic != nil && [_currentCharacteristic.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString] == YES) {
                [self writeDataWithIdx:characteristic.UUID.UUIDString.integerValue];
            }else{
                [_peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateState:)] == YES) {
        [self.delegate manager:self didUpdateState:MKBLEStateStandby];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error != nil) {
        DDLogInfo(@"No datas");
        DDLogInfo(@"%@", error);
        return;
    }
    uint8 i;
    [characteristic.value getBytes:&i length:sizeof(i)];
    // 更新本地Model
    if ([self.delegate respondsToSelector:@selector(manager:didUpdateValue:forIndex:)] == YES) {
        [self.delegate manager:mgr didUpdateValue:i forIndex:[MKConvertor numberWithHexString:characteristic.UUID.UUIDString]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    DDLogError(@"写入%@", error);
    if (error == nil) {
        // 更新本地Model
        if ([self.delegate respondsToSelector:@selector(manager:didUpdateValue:forIndex:)] == YES) {
            [self.delegate manager:mgr didUpdateValue:_currentValue forIndex:_currentCharacteristic.UUID.UUIDString.integerValue];
        }
        _currentValue = NSIntegerMax;
        _currentCharacteristic = nil;
//        // 写入成功
//        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.model];
//        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
//        [user setObject:data forKey:@"dataModel"];
//        //同步到本地
//        [user synchronize];
//        _currentValue = 0;
    }
}

- (void)addSavedDevice:(NSUUID *)uuid{
    NSArray *storedDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSMutableArray *newDevices = nil;
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        DDLogError(@"Can't find/create an array to store the uuid");
    }
    newDevices = [NSMutableArray arrayWithArray:storedDevices];
    if (uuid) {
        [newDevices removeAllObjects];
        [newDevices addObject:uuid.UUIDString];
    }
    /* Store */
    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)loadSavedDevices{
    NSArray *storedDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        DDLogInfo(@"No stored array to load");
        return NO;
    }
    for (NSString *deviceUUIDString in storedDevices) {
        if (![deviceUUIDString isKindOfClass:[NSString class]]) continue;
        NSArray<CBPeripheral *> *deviceArr = [_centralManager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:[[NSUUID alloc] initWithUUIDString:deviceUUIDString]]];
        _peripheral = deviceArr.firstObject;
        if (_peripheral != nil) {
            [self.centralManager connectPeripheral:_peripheral options:@{}];
            self.timerCounter = connectionTimeoutInterval;
            [self.timer setFireDate:[NSDate distantPast]];
        }else{
            return NO;
        }
    }
    return YES;
}


-(void)writeDataWithIdx:(MKC_UUID_IDX)uuid_idx{
    char data = _currentValue;
    Byte b[1] = {data};
    NSData *writeData = [NSData dataWithBytes:b length:sizeof(b)];
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:writeData forCharacteristic:_currentCharacteristic type:CBCharacteristicWriteWithResponse];
        [_peripheral readValueForCharacteristic:_currentCharacteristic];
    }
}

- (void)loadData{
//    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
//    NSData *data = [user objectForKey:@"dataModel"];
//    self.model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.currentValue = NSIntegerMax;
}

- (void)setDataAtIdx:(MKC_UUID_IDX)uuid_idx value:(NSInteger)value{
    _currentValue = value;
    for (CBCharacteristic *character in _service.characteristics) {
        if ([MKConvertor numberWithHexString:character.UUID.UUIDString] == uuid_idx) {
            _currentCharacteristic = character;
            [self writeDataWithIdx:uuid_idx];
            return;
            break;
        }
    };
//    [_peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:[MKConvertor stringWithHexNumber:uuid_idx]]] forService:_service];
}

- (void)getDataAtIdx:(MKC_UUID_IDX)idx{
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:[MKConvertor stringWithHexNumber:idx]]] forService:_service];
    }
}

- (void)getDatas{
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral discoverCharacteristics:[self getAllCharacteristicUUID] forService:_service];
    }
}

- (NSArray *)getAllCharacteristicUUID{
    NSMutableArray *mArr = [NSMutableArray array];
    for (int i = MKC_UUID_IDX_SV; i < MKC_UUID_IDX_NB; ++i) {
        CBUUID *uuid = [CBUUID UUIDWithString:[MKConvertor stringWithHexNumber:i]];
        [mArr addObject:uuid];
    }
    return mArr.copy;
}

- (void)resetConnection{
    /* Store */
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
