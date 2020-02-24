//
//  MKDialogueVC.m
//  mkcooling
//
//  Created by mist on 2020/2/21.
//  Copyright © 2020 mist. All rights reserved.
//

#import "MKDialogueVC.h"

@interface MKDialogueVC ()

@property (weak) IBOutlet NSButton *openBluetoothButton;

@property (weak) IBOutlet NSButton *resetButton;

@end

@implementation MKDialogueVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.openBluetoothButton.bezelStyle = NSBezelStyleRounded;
    self.openBluetoothButton.keyEquivalent = @"\r";
    self.openBluetoothButton.highlighted = YES;
}

- (IBAction)resetButtonClicked:(NSButton *)sender{
    [self.view.window close];
    return;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNAME_RESETCONNECTION object:nil];
}

- (IBAction)openButtonClicked:(NSButton *)sender{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.bluetooth"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

@end
