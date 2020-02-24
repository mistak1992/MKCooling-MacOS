//
//  AppDelegate.m
//  mkcoolingLauncher
//
//  Created by mist on 2019/10/16.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *mainAppIdentifier = @"com.mistak1992.mkcooling";
    [[[NSWorkspace sharedWorkspace] runningApplications] enumerateObjectsUsingBlock:^(NSRunningApplication * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bundleIdentifier isEqualToString:mainAppIdentifier] == YES) {
            [self terminate];
            *stop = YES;
        }else if (idx == [[NSWorkspace sharedWorkspace] runningApplications].count - 1){
            [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(terminate) name:kNotificationNAME_KILLLAUNCHER object:mainAppIdentifier];
            NSString *path = [NSBundle mainBundle].bundlePath;
            NSMutableArray *pathComponents = path.pathComponents.mutableCopy;
            [pathComponents removeLastObject];
            [pathComponents removeLastObject];
            [pathComponents removeLastObject];
            [pathComponents addObject:@"MacOS"];
            [pathComponents addObject:@"mkcooling"];
            NSString *pathNew = [NSString pathWithComponents:pathComponents];
            [[NSWorkspace sharedWorkspace] launchApplication:pathNew];
        }
    }];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)terminate{
    exit(0);
}

@end
