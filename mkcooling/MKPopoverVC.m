//
//  MKPopoverVC.m
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import "MKPopoverVC.h"

#import "MKMicrophoneTool.h"

#import <ServiceManagement/ServiceManagement.h>

@interface MKPopoverVC () <NSWindowDelegate>

@property (weak) IBOutlet NSButton *switchCheckButton;

@property (weak) IBOutlet NSButton *launchOnBootButton;

@property (weak) IBOutlet NSPopUpButton *modeList;

@property (nonatomic, strong) MKMicrophoneTool *microphoneTool;

@end

@implementation MKPopoverVC

- (instancetype)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
        
    }
    return self;
}

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
    }
    return self;
}

#pragma mark - 设置工具
- (void)setupTool{
    // 初始化监听工具
//    self.microphoneTool = [MKMicrophoneTool sharedMicrophoneTool];
    // 设置监听
    [self.switchCheck setTarget:self];
    [self.switchCheck setAction:@selector(switchCheckBoxValueChanged:)];
    [self.fanRPMSlider setTarget:self];
    [self.fanRPMSlider setAction:@selector(soundSliderValueChanged:)];
    // 读取用户记录
    NSDictionary *userDefault = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDefault"];
    if (userDefault != nil) {
        self.switchCheck.state = [userDefault[@"switchValue"] longValue];
        [self switchCheckBoxValueChanged:self.switchCheck];
        [self.fanRPMSlider setDoubleValue:[userDefault[@"RPMValue"] floatValue]];
        [self soundSliderValueChanged:self.fanRPMSlider];
        self.launchOnBootCheck.state = [userDefault[@"launchOnBoot"] longValue];
        [self launchOnBootCheckBoxValueChanged:self.launchOnBootCheck];
        [self.modeList selectItemAtIndex:[userDefault[@"currentMode"] longValue]];
        [self setUIWithMode:[userDefault[@"currentMode"] intValue]];
    }
    NSString *launchHelperIdentifier = @"com.mistak1992.mkcoolingLauncher";
    NSArray *arr = (__bridge NSArray*)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj allKeys] containsObject:@"Label"] == YES && [obj[@"Label"] isEqualToString:launchHelperIdentifier] == YES) {
            DDLogDebug(@"----------------%@", obj[@"Label"]);
            self.launchOnBootCheck.state = 1.0;
            *stop = YES;
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setupTool];
    [self.modeList setAction:@selector(modeListAction:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMode:) name:kNotificationNAME_MODECHANGED object:nil];
}

#pragma mark - 选择模式
- (void)modeListAction:(NSPopUpButton *)button{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_MODECHANGED object:nil userInfo:@{@"currentMode":[NSNumber numberWithLong:button.indexOfSelectedItem]}];
}

#pragma mark - 切换模式通知接受
- (void)changeMode:(NSNotification *)notification{
    MKCoolerMode mode = [notification.userInfo[@"currentMode"] longValue];
    [self setUIWithMode:mode];
}

#pragma mark - 设置界面UI
- (void)setUIWithMode:(MKCoolerMode)mode{
    switch (mode) {
        case MKCoolerModeOff:{
            self.fanRPMSlider.enabled = YES;
            break;
        }
        case MKCoolerModeSystem:{
            self.fanRPMSlider.enabled = NO;
            break;
        }
        case MKCoolerModeAI:{
            self.fanRPMSlider.enabled = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark - 开关开启关闭
- (IBAction)switchCheckBoxValueChanged:(NSButton *)sender {
    MKCoolerState state;
    if (sender.state == NSControlStateValueOn) {
        state = MKCoolerStateRunning;
    }else{
        state = MKCoolerStateOff;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_STATECHANGED object:nil userInfo:@{@"state":[NSNumber numberWithLong:state]}];
}

#pragma mark - 音量大小调节
- (IBAction)soundSliderValueChanged:(NSSlider *)sender{
    CGFloat volume = sender.floatValue / 100;
//    [self.microphoneTool setVolume:volume];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RPM object:nil userInfo:@{@"fan_rpm":[NSString stringWithFormat:@"%d", (int)(volume * 100)]}];
}

#pragma mark - 开机启动
- (IBAction)launchOnBootCheckBoxValueChanged:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
        [self setLaunchOnBoot:YES];
    }else{
        [self setLaunchOnBoot:NO];
    }
}

#pragma mark - 退出按钮
- (IBAction)exitButtonClicked:(NSButton *)sender {
    NSDictionary *userDefault = @{@"switchValue":[NSNumber numberWithLong:self.switchCheck.state], @"RPMValue":[NSNumber numberWithFloat:self.fanRPMSlider.floatValue], @"launchOnBoot":[NSNumber numberWithLong:self.launchOnBootCheck.state], @"currentMode":[NSNumber numberWithLong:self.modeList.indexOfSelectedItem]};
    [[NSUserDefaults standardUserDefaults] setObject:userDefault forKey:@"userDefault"];
    exit(0);
}

#pragma mark - 设置开机启动
- (void)setLaunchOnBoot:(BOOL)isLaunchOnBoot{
    NSString *launchHelperIdentifier = @"com.mistak1992.mkcoolingLauncher";
    DDLogDebug(@"%d", SMLoginItemSetEnabled((__bridge CFStringRef)launchHelperIdentifier, isLaunchOnBoot));
}

- (void)windowDidResignKey:(NSNotification *)notification{
    DDLogDebug(@"aaaaaaa");
}

- (IBAction)resetButtonClicked:(NSButton *)sender{
    MKDialogueC *c = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MKDialogueC"];
    [c showWindow:self];
}

@end
