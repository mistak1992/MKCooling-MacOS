//
//  MKMainController.m
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import "MKMainController.h"

#import "MKBLEManager.h"

#import "smcWrapper.h"

@interface MKMainController () <MKBLEManagerDelegate, MKBLEManagerDatasource>
// 状态栏
@property (nonatomic, strong) NSStatusItem *statusBar;
// 弹出窗
@property (nonatomic, strong) NSPopover *popover;

@property (nonatomic, strong) MKDataController *dataController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) MKBLEDataModel *model;

@property (nonatomic, assign) NSInteger interval;

@property (nonatomic, assign) NSInteger counter;

@property (nonatomic, assign) MKCoolerMode mode;

@property (nonatomic, assign) int systemModeFanMin;

@property (nonatomic, assign) int systemModeFanMax;

@property (nonatomic, assign) CGFloat currentFanDuty;

@property (nonatomic, assign) MKBLEState BLEState;

@property (nonatomic, assign) NSInteger fetchDelayCounter;

@end

@implementation MKMainController

#pragma mark - 点击状态栏
- (void)statusBarButtonClick:(NSButton *)sender{
    [self.popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMaxY];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)dismissPopover:(NSNotification *)notification{
    [_popover close];
}

- (void)resetConnection:(NSNotification *)notification{
    [[MKBLEManager sharedSingleton] stop];
    [[MKBLEManager sharedSingleton] start];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)timerAction:(NSTimer *)timer{
    if (_fetchDelayCounter > 0) {
        _fetchDelayCounter--;
    }else{
        _fetchDelayCounter = (self.model.delay == 0 ? kDEFAULT_MAX_FETCHINFO_DELAY + 1 : self.model.delay);
        if ([[MKDate date] compare:[NSDate dateWithTimeIntervalSince1970:self.model.update_time.timeIntervalSince1970 + _fetchDelayCounter]] == NSOrderedAscending) {
            NSLog(@"还没到时间");
        }else{
            // fetchData
            if ([MKBLEManager sharedSingleton].state == MKBLEStateConnected) {
                NSLog(@"到时间");
                [[MKBLEManager sharedSingleton] setDevice:[MKBLEManager sharedSingleton].discoveredDevices.firstObject forFunction:MKBLEFunctionFetchInfo];
            }
        }
    }
    if (_counter > 0) {
        _counter--;
    }else{
        _counter = _interval;
        if (_BLEState == MKBLEStateConnected) {
            // 动作
            switch (self.state) {
                case MKCoolerStateRunning:{
                    switch (self.mode) {
                        case MKCoolerModeOff:{
                            
                            break;
                        }
                        case MKCoolerModeSystem:{
                            //获取系统转速
                            CGFloat percentage = ([smcWrapper get_fan_rpm:0] - self.systemModeFanMin) / (double)(self.systemModeFanMax - self.systemModeFanMin);
                            if (percentage < 0) {
                                percentage = 0;
                            }
                            NSInteger fan_percentage = percentage * 100;
                            if (self.model.fan_percentage != fan_percentage) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_duty":[NSString stringWithFormat:@"%d", (int)fan_percentage]}];
                            }
        //                    self.currentFanDuty = percentage;
                            break;
                        }
                        case MKCoolerModeCPULoad:{
                            //获取CPU负载
                            
        //                    NSArray *temp = [[MKCpuTool sharedSingleton] getCPULoadRecords];
                            CGFloat cpuLoad = [MKCpuTool getCPULoadMax];
                            // +-一成范围内不变
                            if (cpuLoad <= self.currentFanDuty + 0.1 && cpuLoad >= self.currentFanDuty - 0.1) {
                                cpuLoad = self.currentFanDuty;
                            }
                            // 慢下降
                            if (cpuLoad < self.currentFanDuty - 0.1) {
                                cpuLoad -= 0.05;
                            }
                            if (cpuLoad < 0) {
                                cpuLoad = 0;
                            }
                            NSInteger fan_percentage = cpuLoad * 100;
                            if (self.model.fan_percentage != fan_percentage) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_duty":[NSString stringWithFormat:@"%d", (int)fan_percentage]}];
                            }
        //                    self.currentFanDuty = cpuLoad;
                            break;
                        }
                        case MKCoolerModeAI:{
                            // 获取5个计算平均值
//                                NSArray *arr = [[MKDataController sharedSingleton] getRecentDatasWithNumber:5];
//                                NSString *text = [NSString string];
//                                NSMutableArray *mArr = [NSMutableArray array];
//                                CGFloat min = 255;
//                                CGFloat max = 0;
//                                CGFloat total = 0;
//                                for (MKBLEDataModel *m in arr) {
//                                    CGFloat current = [NSString stringWithFormat:@"%ld.%ld", m.ir_tempo_int, m.ir_tempo_dec].doubleValue;
//                                    [mArr addObject:[NSNumber numberWithDouble:current]];
//                                    if (current < min) {
//                                        min = current;
//                                    }
//                                    if (current > max) {
//                                        max = current;
//                                    }
//                                    total += current;
//                                }
//                                total = total - min - max;
//                                CGFloat avg = total / 3;
//                                if ([mArr.lastObject floatValue] > avg) {
//                                    text = @"hotter";
//                                }else{
//                                    text = @"cooler";
//                                }
                            break;
                        }
                        default:
                            break;
                    }
                }
                default:
                    break;
            }
            //    MKPopoverVC *popVC = (MKPopoverVC *)self.popover.contentViewController;
            //    NSDateFormatter *form = [NSDateFormatter new];
            //    form.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            //    NSString *text = [form stringFromDate:[NSDate date]];
            //    popVC.textView.placeholderString = text;//text;
        }
        
    }
}

- (NSTimer *)timer{
    if (_timer == nil) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

#pragma mark - 状态栏懒加载
- (NSStatusItem *)statusBar{
    if (_statusBar == nil) {
        // 设置状态栏
        _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        if (@available(macOS 10.14, *)) {
            _statusBar.button.image = [NSImage imageNamed:@"statusBarIconDark"];
        }else{
            _statusBar.image = [NSImage imageNamed:@"statusBarIconDark"];
        }
        
        [_statusBar.button setTarget:self];
    }
    return _statusBar;
}

#pragma mark - 弹出窗懒加载
- (NSPopover *)popover{
    if (_popover == nil) {
        _popover = [[NSPopover alloc] init];
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.animates = NO;
        _popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    }
    return _popover;
}

- (void)needUpdateBLEData:(NSNotification *)notification{
    NSDictionary *dic = notification.userInfo;
    [[dic allKeys] enumerateObjectsUsingBlock:^(NSString * keyName, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([keyName isEqualToString:@"fan_duty"] == YES) {
            self.currentFanDuty = [dic[@"fan_duty"] integerValue];
            [self setBLEData:dic[@"fan_duty"]];
        }
    }];
}

- (void)setBLEData:(NSString *)valueStr{
    if ([MKBLEManager sharedSingleton].discoveredDevices.count == 1) {
        [[MKBLEManager sharedSingleton] setDevice:[MKBLEManager sharedSingleton].discoveredDevices.firstObject forFunction:MKBLEFunctionSetFanDuty];
    }
    
}

- (void)manager:(MKBLEManager *)manager didUpdateState:(MKBLEState)state{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_BLESTATECHANGED object:nil userInfo:@{@"BLEState":[NSNumber numberWithInt:(int)state]}];
    _BLEState = state;
    switch (state) {
        case MKBLEStatePoweredOn:{
            if (_isWakeUp == YES) {
                _isWakeUp = NO;
                [manager start];
            }
            break;
        }
        case MKBLEStateConnected:{
            [self.timer setFireDate:[NSDate distantPast]];
            break;
        }
        default:
            [self.timer setFireDate:[NSDate distantFuture]];
            break;
    }
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [manager setDataAtIdx:MKC_UUID_IDX_FAN_PERCENTAGE value:100];
//    });
}

- (void)manager:(MKBLEManager *)manager didDiscoveredDevices:(NSArray<MKBLEDeviceModel *> *)devices{
    if (devices.count == 1) {
//        DDLogInfo(@"found 1 and state%ld", (long)manager.state);
        if (manager.state == MKBLEStateScanning || manager.state == MKBLEStatePoweredOn) {
            [manager setDevice:devices.firstObject forFunction:MKBLEFunctionFetchInfo];
        }
    }
}

- (void)manager:(MKBLEManager *)manager result:(MKBLEResult)result ofDeviceModel:(MKBLEDeviceModel *)deviceModel forFunction:(MKBLEFunction)function withResponseData:(nullable NSData *)data{
    if (data.length > 0) {
        [self.model setDataModelWithRawData:data];
        // 存储
        [[MKDataController sharedSingleton] saveBLEModel:self.model];
//        NSLog(@"%ld", self.model.fan_percentage);
    }
}

- (NSDictionary *)manager:(MKBLEManager *)manager userInfoForFuntion:(MKBLEFunction)function{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    switch (function) {
        case MKBLEFunctionSetFanDuty:{
            [userInfo setObject:[NSNumber numberWithInt:(int)_currentFanDuty] forKey:@"fanDuty"];
            break;
        }
        case MKBLEFunctionSetDelay:{
            [userInfo setObject:[NSNumber numberWithInt:(int)kDEFAULT_MAX_FETCHINFO_DELAY] forKey:@"delay"];
            break;
        }
        default:
            break;
    }
    return userInfo.copy;
}

- (NSArray<MKBLEDeviceModel *> *)retrievePeripheralsWithDeviceModelsForManager:(MKBLEManager *)manager{
    NSArray *storedDatas = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSMutableArray *storedDevices = [NSMutableArray array];
    for (NSData *data in storedDatas) {
        MKBLEDeviceModel *deviceModel = nil;
        if (@available(macOS 10.13, *)) {
            deviceModel = [NSKeyedUnarchiver unarchivedObjectOfClass:[MKBLEDeviceModel class] fromData:data error:nil];
        } else {
            // Fallback on earlier versions
            deviceModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        [storedDevices addObject:deviceModel];
    }
    return storedDevices.copy;
}

- (void)manager:(MKBLEManager *)manager persistPeripheralWithDeviceModel:(nonnull MKBLEDeviceModel *)deviceModel{
    NSArray *storedDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSMutableArray *newDevices = nil;
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        DDLogError(@"Can't find/create an array to store the uuid");
    }
    newDevices = [NSMutableArray arrayWithArray:storedDevices];
    if ([deviceModel isKindOfClass:[MKBLEDeviceModel class]] == YES) {
        [newDevices removeAllObjects];
        NSData *deviceData;
        if (@available(macOS 10.13, *)) {
            NSError *err;
            deviceData = [NSKeyedArchiver archivedDataWithRootObject:deviceModel requiringSecureCoding:YES error:&err];
            if (err != nil) {
                NSLog(@"%@", err);
            }
        } else {
            // Fallback on earlier versions
            deviceData = [NSKeyedArchiver archivedDataWithRootObject:deviceModel];
        }
        [newDevices addObject:deviceData];
    }
    /* Store */
    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark 界面部分
- (instancetype)init{
    if (self = [super init]) {
        [smcWrapper init];
        [self setupCoreData];
        [self setup];
    }
    return self;
}

#pragma mark - 设置数据库
- (void)setupCoreData{
    [MKDataController sharedSingleton];
    self.model = [[MKDataController sharedSingleton] getBLEModel];
}

#pragma mark - 设置界面
- (void)setup{
    self.interval = 2;
    [MKBLEManager sharedSingleton].delegate = self;
    [MKBLEManager sharedSingleton].datasource = self;
    [[MKBLEManager sharedSingleton].whiteList addObject:deviceMAC]; //3c71bf5933ca
    // 加载状态栏
    [self.statusBar.button setAction:@selector(statusBarButtonClick:)];
    // 设置弹出窗口
    self.popover.contentViewController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"popoverContentVC"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needUpdateBLEData:) name:kNotificationNAME_RPM object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopover:) name:kNotificationNAME_RESIGNACTIVE object:nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @0, PREF_TEMP_UNIT,
            @0, PREF_SELECTION_DEFAULT,
            @NO,PREF_AUTOSTART_ENABLED,
            @NO,PREF_AUTOMATIC_CHANGE,
            @0, PREF_BATTERY_SELECTION,
            @0, PREF_AC_SELECTION,
            @0, PREF_CHARGING_SELECTION,
            @0, PREF_MENU_DISPLAYMODE,
            @"TC0D",PREF_TEMPERATURE_SENSOR,
            @0, PREF_NUMBEROF_LAUNCHES,
            @NO,PREF_DONATIONMESSAGE_DISPLAY,
            [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],PREF_MENU_TEXTCOLOR,
    nil]];
    self.systemModeFanMax = [smcWrapper get_max_speed:0];
    self.systemModeFanMin = [smcWrapper get_min_speed:0];
    DDLogDebug(@"CPU温度:%lf 风扇转速:%d 最大转速:%d 最小转速:%d", [smcWrapper get_maintemp], [smcWrapper get_fan_rpm:0], [smcWrapper get_max_speed:0], [smcWrapper get_min_speed:0]);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUpButtonAction:) name:kNotificationNAME_MODECHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needChangeState:) name:kNotificationNAME_STATECHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetConnection:) name:kNotificationNAME_RESETCONNECTION object:nil];
    // 读取用户记录
    NSDictionary *userDefault = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDefault"];
    if (userDefault != nil) {
        [self setMode:[userDefault[@"currentMode"] longValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_duty":[NSString stringWithFormat:@"%d", (int)([userDefault[@"RPMValue"] floatValue] * 100)]}];
    }
    //
//    ProcInfo* procInfo = [[ProcInfo alloc] init:NO];
//    NSLog(@"%@", [procInfo currentProcesses]);
    
}

- (void)popUpButtonAction:(NSNotification *)notification{
    MKCoolerMode currentMode = [notification.userInfo[@"currentMode"] intValue];
    [self setMode:currentMode];
}

- (void)needChangeState:(NSNotification *)notification{
    MKCoolerState state = [notification.userInfo[@"state"] intValue];
    [self setState:state];
}

- (void)setMode:(MKCoolerMode)mode{
    _mode = mode;
    switch (mode) {
        case MKCoolerModeOff:{
            
            break;
        }
        case MKCoolerModeSystem:{
            
            break;
        }
        case MKCoolerModeAI:{
            
            break;
        }
        default:
            break;
    }
}

- (void)setState:(MKCoolerState)state{
    _state = state;
    switch (state) {
        case MKCoolerStateSleep:{
            [self.timer setFireDate:[NSDate distantFuture]];
            break;
        }
        case MKCoolerStateIdle:{
            _state = MKCoolerStateRunning;
            break;
        }
        case MKCoolerStateRunning:{
            [self.timer setFireDate:[NSDate distantPast]];
            break;
        }
        case MKCoolerStateOff:{
            [self.timer setFireDate:[NSDate distantFuture]];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_duty":[NSString stringWithFormat:@"%d", 0]}];
            break;
        }
        default:
            break;
    }
}

@end
