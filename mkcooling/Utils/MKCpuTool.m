//
//  MKCpuTool.m
//  mkcooling
//
//  Created by mist on 2020/3/19.
//  Copyright © 2020 mist. All rights reserved.
//

#import "MKCpuTool.h"
#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

processor_info_array_t cpuInfo, prevCpuInfo;
mach_msg_type_number_t numCpuInfo, numPrevCpuInfo;
unsigned numCPUs;
NSLock *CPUUsageLock;
BOOL isInit = false;

static MKCpuTool *tool = nil;

@interface MKCpuTool ()

@property (nonatomic, strong) NSMutableArray *loadRecords;

@end

@implementation MKCpuTool

+ (NSArray *)getCPULoadTotal{
    NSMutableArray *arr = [NSMutableArray array];
    if (isInit == false) {
        int mib[2U] = { CTL_HW, HW_NCPU };
        size_t sizeOfNumCPUs = sizeof(numCPUs);
        int status = sysctl(mib, 2U, &numCPUs, &sizeOfNumCPUs, NULL, 0U);
        if(status)
            numCPUs = 1;
        CPUUsageLock = [[NSLock alloc] init];
        isInit = true;
    }
    natural_t numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    if(err == KERN_SUCCESS) {
        [CPUUsageLock lock];

        for(unsigned i = 0U; i < numCPUs; ++i) {
            float inUse, total;
            if(prevCpuInfo) {
                inUse = (
                         (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                         );
                total = inUse + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                inUse = cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total = inUse + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
//            NSLog(@"Core: %u Usage: %f",i,inUse / total);
            [arr addObject:[NSNumber numberWithFloat: (float)(inUse / total)]];
        }
        [CPUUsageLock unlock];

        if(prevCpuInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * numPrevCpuInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)prevCpuInfo, prevCpuInfoSize);
        }

        prevCpuInfo = cpuInfo;
        numPrevCpuInfo = numCpuInfo;

        cpuInfo = NULL;
        numCpuInfo = 0U;
        return [arr copy];
    } else {
        NSLog(@"Error!");
        [NSApp terminate:nil];
        return nil;
    }
}

+ (double)getCPULoadAvg{
    NSArray *arr = [self getCPULoadTotal];
    double total = 0;
    for (NSNumber *value in arr) {
        total += [value doubleValue];
    }
    double avg = total / numCPUs;
    return avg;
}

+ (double)getCPULoadMax{
    NSArray *arr = [self getCPULoadTotal];
    double max = [[arr valueForKeyPath:@"@max.floatValue"] floatValue];
    return max;
}

+ (double)getCPULoadByCoreIndex:(unsigned int)coreIndex{
    if (isInit == false) {
        int mib[2U] = { CTL_HW, HW_NCPU };
        size_t sizeOfNumCPUs = sizeof(numCPUs);
        int status = sysctl(mib, 2U, &numCPUs, &sizeOfNumCPUs, NULL, 0U);
        if(status)
            numCPUs = 1;
        CPUUsageLock = [[NSLock alloc] init];
        isInit = true;
    }
    natural_t numCPUsU = coreIndex;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    if(err == KERN_SUCCESS && coreIndex < numCPUs && coreIndex >= 0) {
        [CPUUsageLock lock];
        float inUse, total;
        if(prevCpuInfo) {
            inUse = (
                     (cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_USER]   - prevCpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_USER])
                     + (cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_SYSTEM] - prevCpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_SYSTEM])
                     + (cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_NICE]   - prevCpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_NICE])
                     );
            total = inUse + (cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_IDLE] - prevCpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_IDLE]);
        } else {
            inUse = cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_USER] + cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_SYSTEM] + cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_NICE];
            total = inUse + cpuInfo[(CPU_STATE_MAX * coreIndex) + CPU_STATE_IDLE];
        }
//        NSLog(@"Core: %u Usage: %f", coreIndex, inUse / total);
        [CPUUsageLock unlock];

        if(prevCpuInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * numPrevCpuInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)prevCpuInfo, prevCpuInfoSize);
        }

        prevCpuInfo = cpuInfo;
        numPrevCpuInfo = numCpuInfo;

        cpuInfo = NULL;
        numCpuInfo = 0U;
        return inUse / total;
    } else {
        NSLog(@"Error!");
        [NSApp terminate:nil];
        return 0;
    }
}

+ (instancetype)sharedSingleton{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 要使用self来调用
        tool = [[self alloc] init];
    });
    return tool;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

- (NSMutableArray *)loadRecords{
    if (_loadRecords == nil) {
        _loadRecords = [NSMutableArray arrayWithCapacity:arrayLength];
    }
    return _loadRecords;
}

- (NSArray *)getCPULoadRecords{
    double avgNew = [MKCpuTool getCPULoadAvg];
    for (int i = arrayLength - 1; i >= 0; --i) {
        if (i != 0) {
            self.loadRecords[i] = self.loadRecords[i - 1];
        }else{
            [self.loadRecords setObject:[NSNumber numberWithDouble:avgNew] atIndexedSubscript:i];
        }
    }
    return self.loadRecords.copy;
}

@end
