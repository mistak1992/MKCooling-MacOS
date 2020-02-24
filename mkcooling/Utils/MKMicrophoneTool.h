//
//  MKMicrophoneTool.h
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKMicrophoneTool : NSObject
/**
 单例

 @return 单例对象
 */
+ (instancetype)sharedMicrophoneTool;
/**
 开始录制
 */
- (void)startRecord;
/**
 结束录制
 */
- (void)stopRecord;
/**
 设置音量

 @param volume 音量
 */
- (void)setVolume:(CGFloat)volume;
@end
