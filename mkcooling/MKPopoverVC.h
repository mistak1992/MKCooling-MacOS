//
//  MKPopoverVC.h
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MKPopoverVC : NSViewController
// 开关
@property (weak) IBOutlet NSButton *switchCheck;
// 输入音量
@property (weak) IBOutlet NSSlider *fanRPMSlider;
// 退出按钮
@property (weak) IBOutlet NSButtonCell *exitButton;
// 开机启动按钮
@property (weak) IBOutlet NSButton *launchOnBootCheck;

@property (weak) IBOutlet NSTextField *textView;

@end
