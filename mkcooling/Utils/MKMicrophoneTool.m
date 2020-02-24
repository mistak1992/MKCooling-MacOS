//
//  MKMicrophoneTool.m
//  envsound
//
//  Created by mist on 08/02/2018.
//  Copyright © 2018 mistak1992. All rights reserved.
//

#import "MKMicrophoneTool.h"

#import <AVKit/AVKit.h>

#import <AVFoundation/AVFoundation.h>

static MKMicrophoneTool *microphoneTool = nil;

static AudioDeviceID defaultDevice = 0;

@interface MKMicrophoneTool ()
// 捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
// 捕捉设备
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
// 输出设备
@property (nonatomic, strong) AVCaptureAudioPreviewOutput *outputDevice;

@end

@implementation MKMicrophoneTool

#pragma mark - 单例
+ (instancetype)sharedMicrophoneTool{
    if (microphoneTool == nil) {
        microphoneTool = [[MKMicrophoneTool alloc] init];
    }
    return microphoneTool;
}

- (instancetype)init{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        microphoneTool = [super init];
    });
    if (self.captureDevice == nil) {
        NSLog(@"初始化失败");
    }else{
        NSLog(@"初始化成功");
        // 监听设备变化
        [self listenToDeviceChange];
    }
    return microphoneTool;
}

#pragma mark - session懒加载
- (AVCaptureSession *)captureSession{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

#pragma mark - device懒加载
- (AVCaptureDevice *)captureDevice{
    if (_captureDevice == nil) {
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        // 添加输入设备
        self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:nil];
        if (self.inputDevice != nil && [self.captureSession canAddInput:self.inputDevice] == YES) {
            [self.captureSession addInput:self.inputDevice];
        }else{
            NSLog(@"添加输入设备失败");
        }
        // 添加输出设备
        self.outputDevice = [[AVCaptureAudioPreviewOutput alloc] init];
        self.outputDevice.volume = 0.0f;
        if (self.outputDevice != nil && [self.captureSession canAddOutput:self.outputDevice] == YES) {
            [self.captureSession addOutput:self.outputDevice];
        }else{
            NSLog(@"添加输出设备失败");
        }
    }
    return _captureDevice;
}

#pragma mark - 开始录制
- (void)startRecord{
    [self.captureSession startRunning];
}

#pragma mark - 结束录制
- (void)stopRecord{
    [self.captureSession stopRunning];
}

#pragma mark - 设置音量
- (void)setVolume:(CGFloat)volume{
    self.outputDevice.volume = volume;
}

#pragma mark - 获取当前输出设备
- (void)checkAudioHardware:(const AudioObjectPropertyAddress *)sourceAddr
{
    UInt32 dataSourceId = 0;
    UInt32 dataSourceIdSize = sizeof(UInt32);
    AudioObjectGetPropertyData(defaultDevice, sourceAddr, 0, NULL, &dataSourceIdSize, &dataSourceId);
    
    if (dataSourceId == 'ispk') {
        NSLog(@"没用耳机");
    } else if (dataSourceId == 'hdpn') {
        NSLog(@"使用耳机");
    }
}

#pragma mark - 监听设备状态变化
- (void)listenToDeviceChange{
    //获得内置输出设备
    UInt32 defaultSize = sizeof(AudioDeviceID);
    const AudioObjectPropertyAddress defaultAddr ={
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultAddr, 0, NULL, &defaultSize, &defaultDevice);
    
    //注册输出设备改变的通知
    AudioObjectPropertyAddress sourceAddr;
    sourceAddr.mSelector = kAudioDevicePropertyDataSource;
    sourceAddr.mScope = kAudioDevicePropertyScopeOutput;
    sourceAddr.mElement = kAudioObjectPropertyElementMaster;
    AudioObjectAddPropertyListenerBlock(defaultDevice, &sourceAddr, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        [self checkAudioHardware:inAddresses];
    });
    
    //第一次主动检测
    [self checkAudioHardware:&sourceAddr];
}
@end
