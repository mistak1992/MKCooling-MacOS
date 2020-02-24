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

@interface MKPopoverVC ()

@property (nonatomic, strong) MKMicrophoneTool *microphoneTool;

@end

@implementation MKPopoverVC

- (instancetype)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
        [self setupTool];
    }
    return self;
}

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setupTool];
    }
    return self;
}

#pragma mark - 设置工具
- (void)setupTool{
    // 初始化监听工具
    self.microphoneTool = [MKMicrophoneTool sharedMicrophoneTool];
    // 设置监听
    [self.switchCheck setTarget:self];
    [self.switchCheck setAction:@selector(switchCheckBoxValueChanged:)];
    [self.inputSoundSlider setTarget:self];
    [self.inputSoundSlider setAction:@selector(soundSliderValueChanged:)];
    // 读取用户记录
    NSDictionary *userDefault = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDefault"];
    if (userDefault != nil) {
        self.switchCheck.state = [userDefault[@"switchValue"] longValue];
        [self switchCheckBoxValueChanged:self.switchCheck];
        [self.inputSoundSlider setDoubleValue:[userDefault[@"volValue"] floatValue]];
        [self soundSliderValueChanged:self.inputSoundSlider];
        self.launchOnBootCheck.state = [userDefault[@"launchOnBoot"] longValue];
        [self launchOnBootCheckBoxValueChanged:self.launchOnBootCheck];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - 开关开启关闭
- (IBAction)switchCheckBoxValueChanged:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
        [self.microphoneTool startRecord];
    }else{
        [self.microphoneTool stopRecord];
    }
}

#pragma mark - 音量大小调节
- (IBAction)soundSliderValueChanged:(NSSlider *)sender {
    CGFloat volume = sender.floatValue / 100;
    [self.microphoneTool setVolume:volume];
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
    NSDictionary *userDefault = @{@"switchValue":[NSNumber numberWithLong:self.switchCheck.state], @"volValue":[NSNumber numberWithFloat:self.inputSoundSlider.floatValue], @"launchOnBoot":[NSNumber numberWithLong:self.launchOnBootCheck.state]};
    [[NSUserDefaults standardUserDefaults] setObject:userDefault forKey:@"userDefault"];
    exit(0);
}

#pragma mark - 设置开机启动
- (void)setLaunchOnBoot:(BOOL)isLaunchOnBoot{
    SMLoginItemSetEnabled((__bridge CFStringRef)@"com.mistak1992.envsound", isLaunchOnBoot);
}

//----------------------------------------------------------------------------
+ (void) setStartAtLoginEnabled:(BOOL)isEnabled
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItems)
    {
        if (isEnabled)
        {
            //Insert an item to the list.
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                         kLSSharedFileListItemLast, NULL, NULL,
                                                                         url, NULL, NULL);
            if (item)
            {
                CFRelease(item);
            }
            
        }
        else
        {
            UInt32 seedValue;
            CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
            
            for (id item in (__bridge NSArray *)loginItemsArray)
            {
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
                url = LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL);
                if (url)
                {
                    NSString* urlPath = [(__bridge NSURL*)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame)
                    {
                        LSSharedFileListItemRemove(loginItems, itemRef);
                    }
                    CFRelease(url);
                }
            }
            CFRelease(loginItemsArray);
        }
        
        CFRelease(loginItems);
    }
    
}

//----------------------------------------------------------------------------
+ (BOOL) isStartAtLoginEnabled
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    BOOL ret = NO;
    
    if (loginItems)
    {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
        
        for (id item in (__bridge NSArray*)loginItemsArray)
        {
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
            //Resolve the item with URL
            url = LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL);
            if (url)
            {
                NSString* urlPath = [(__bridge NSURL*)url path];
                if ([urlPath compare:appPath] == NSOrderedSame)
                {
                    ret = YES;
                }
                CFRelease(url);
            }
        }
        CFRelease(loginItemsArray);
        CFRelease(loginItems);
    }
    
    return ret;
}

@end
