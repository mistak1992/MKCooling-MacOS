//
//  AppDelegate.m
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import "AppDelegate.h"

#import "MKMainController.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface AppDelegate ()

@property (nonatomic, strong) MKMainController *vc;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // init Logger
    [DDLog addLogger:[DDOSLogger sharedInstance]]; // Uses os_log
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *logfileURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]; //mkcooling.log
    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:documentPath];
//    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] init];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    fileLogger.rollingFrequency = 60; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    NSLog(@"%@", fileLogger.logFileManager.logsDirectory);
    [DDLog addLogger:fileLogger];
    
    // Insert code here to initialize your application
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        if ([window isMemberOfClass:[NSWindow class]]) {
            [window close];
        }
    }
    NSString *launcherAppId = @"com.mistak1992.mkcoolingLauncher";
    [[[NSWorkspace sharedWorkspace] runningApplications] enumerateObjectsUsingBlock:^(NSRunningApplication * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bundleIdentifier isEqualToString:launcherAppId] == YES) {
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_KILLLAUNCHER object:[NSBundle mainBundle].bundleIdentifier];
        }
    }];
    // mainController
    _vc = [[MKMainController alloc] init];
    // sleep/wake
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onSleepNote:) name:NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onWakeNote:) name:NSWorkspaceDidWakeNotification object:nil];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)applicationWillResignActive:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RESIGNACTIVE object:nil];
}

- (void)onSleepNote:(NSNotification *)notification{
    _vc.state = MKCoolerStateSleep;
}

- (void)onWakeNote:(NSNotification *)notification{
    _vc.state = MKCoolerStateIdle;
}

@end
