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

@interface MKMainController () <MKBLEManagerDelegate>
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

@property (nonatomic, assign) MKBLEState BLEState;

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
    [[MKBLEManager sharedSingleton] resetConnection];
}

- (void)timerAction:(NSTimer *)timer{
    if (_counter > 0) {
        _counter--;
        return;
    }
    _counter = _interval;
    if (_BLEState != MKBLEStateStandby) {
        return;
    }
//    // 旧的
//    if ([[MKDataController sharedSingleton] saveBLEModel:self.model] == YES) {
//        self.model = [[MKDataController sharedSingleton] getBLEModel];
//    }else{
//
//    }
//    // 获取新的
//    [[MKBLEManager sharedSingleton] getDatas];
//    NSArray *arr = [[MKDataController sharedSingleton] getRecentDatasWithNumber:5];
//    NSString *text = [NSString string];
//    NSMutableArray *mArr = [NSMutableArray array];
//    CGFloat min = 255;
//    CGFloat max = 0;
//    CGFloat total = 0;
//    for (MKBLEDataModel *m in arr) {
//        CGFloat current = [NSString stringWithFormat:@"%ld.%ld", m.ir_tempo_int, m.ir_tempo_dec].doubleValue;
//        [mArr addObject:[NSNumber numberWithDouble:current]];
//        if (current < min) {
//            min = current;
//        }
//        if (current > max) {
//            max = current;
//        }
//        total += current;
//    }
//    total = total - min - max;
//    CGFloat avg = total / 3;
//    if ([mArr.lastObject floatValue] > avg) {
//        text = @"hotter";
//    }else{
//        text = @"cooler";
//    }
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_rpm":[NSString stringWithFormat:@"%d", (int)(percentage * 100)]}];
                    break;
                }
                case MKCoolerModeAI:{
                    
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
        _statusBar.image = [NSImage imageNamed:@"statusBarIconDark"];
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
        if ([keyName isEqualToString:@"fan_rpm"] == YES) {
            [self setBLEData:dic[@"fan_rpm"]];
        }
    }];
}

- (void)setBLEData:(NSString *)valueStr{
    [[MKBLEManager sharedSingleton] setDataAtIdx:MKC_UUID_IDX_FAN_PERCENTAGE value:valueStr.integerValue];
}

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
    self.interval = 2;
    [MKBLEManager sharedSingleton].delegate = self;
    self.model = [[MKDataController sharedSingleton] getBLEModel];
}

#pragma mark - 设置界面
- (void)setup{
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
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_rpm":[NSString stringWithFormat:@"%d", (int)([userDefault[@"RPMValue"] floatValue] * 100)]}];
    }
}

- (void)manager:(MKBLEManager *)manager didUpdateValue:(NSInteger)value forIndex:(MKC_UUID_IDX)index{
    [self setValueWithUUIDIdx:index value:value];
}

- (void)manager:(MKBLEManager *)manager didUpdateState:(MKBLEState)state{
    _BLEState = state;
    switch (state) {
        case MKBLEStatePoweredOn:{
            [manager start];
            break;
        }
        case MKBLEStateStandby:{
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_rpm":[NSString stringWithFormat:@"%d", 0]}];
            break;
        }
        default:
            break;
    }
}

- (void)setValueWithUUIDIdx:(MKC_UUID_IDX)uuid_idx value:(NSInteger)value{
    switch (uuid_idx) {
        case MKC_UUID_IDX_TEMP_INT:{
            self.model.temp_int = value;
            break;
        }
        case MKC_UUID_IDX_TEMP_DEC:{
            self.model.temp_dec = value;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPO_INT:{
            self.model.ir_tempo_int = value;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPO_DEC:{
            self.model.ir_tempo_dec = value;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPA_INT:{
            self.model.ir_tempa_int = value;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPA_DEC:{
            self.model.ir_tempa_dec = value;
            break;
        }
        case MKC_UUID_IDX_FAN_RPM:{
            self.model.fan_rpm = value;
            break;
        }
        case MKC_UUID_IDX_FAN_PERCENTAGE:{
            self.model.fan_percentage = value;
            break;
        }
        case MKC_UUID_IDX_IR_SWITCH:{
            self.model.ir_switch = value;
            break;
        }
        case MKC_UUID_IDX_AUTH_KEY:{
            self.model.auth_key = value;
            break;
        }
        default:
            break;
    }
}

- (NSInteger)getValueWithUUID:(MKC_UUID_IDX)uuid_idx{
    NSInteger data = 0;
    switch (uuid_idx) {
        case MKC_UUID_IDX_TEMP_INT:{
            data = self.model.temp_int;
            break;
        }
        case MKC_UUID_IDX_TEMP_DEC:{
            data = self.model.temp_dec;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPO_INT:{
            data = self.model.ir_tempo_int;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPO_DEC:{
            data = self.model.ir_tempo_dec;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPA_INT:{
            data = self.model.ir_tempa_int;
            break;
        }
        case MKC_UUID_IDX_IR_TEMPA_DEC:{
            data = self.model.ir_tempa_int;
            break;
        }
        case MKC_UUID_IDX_FAN_RPM:{
            data = self.model.fan_rpm;
            break;
        }
        case MKC_UUID_IDX_FAN_PERCENTAGE:{
            data = self.model.fan_percentage;
            break;
        }
        case MKC_UUID_IDX_IR_SWITCH:{
            data = self.model.ir_switch;
            break;
        }
        case MKC_UUID_IDX_AUTH_KEY:{
            data = self.model.auth_key;
            break;
        }
        default:
            break;
    }
    return data;
}

@end
