//
//  MKDataController.m
//  mkcooling
//
//  Created by mist on 2019/10/19.
//  Copyright © 2019 mistak1992. All rights reserved.
//

#import "MKDataController.h"

#import "smcWrapper.h"

static MKDataController *controller = nil;

@interface MKDataController ()

@property (readonly, strong, nonatomic)NSManagedObjectContext *managedObjectContext;
//管理存储对象，数据库的model
@property (readonly, strong, nonatomic)NSManagedObjectModel *managedObjectModel;
//协调者，上下文和model的协调者
@property (readonly, strong, nonatomic)NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, assign) BOOL isOn;

@end

@implementation MKDataController

@synthesize managedObjectContext =_managedObjectContext;
 
@synthesize managedObjectModel = _managedObjectModel;
 
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Core Data
- (NSManagedObjectContext *)managedObjectContext{
    if (_managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _managedObjectContext;
}
 
- (NSManagedObjectModel *)managedObjectModel{
    if (_managedObjectModel == nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MKPersistData"withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}
 
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator{
    if (_persistentStoreCoordinator == nil) {
        //这里的model.sqlite，自己定，最好按业务来
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DataModel.sqlite"];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *options = @{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}};
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil  URL:storeURL options:options error:&error]) {
            DDLogError(@"Unresolvederror %@, %@", error, [error userInfo]);
        }
    }
    return _persistentStoreCoordinator;
}
 
#pragma mark - Application's Documents directory
- (NSURL*)applicationDocumentsDirectory{
    return[[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];
}

- (MKBLEDataModel *)getBLEModel{
    MKBLEDataModel *m = [MKBLEDataModel new];
    [self resetBLEDatas:m];
    return m;
}

- (BOOL)saveBLEModel:(MKBLEDataModel *)model{
    MKBLEDataPresistModel *m = [NSEntityDescription insertNewObjectForEntityForName:@"BLEData" inManagedObjectContext:_managedObjectContext];
    m.auth_key = model.auth_key;
    m.fan_rpm = model.fan_rpm;
    m.fan_percentage = model.fan_percentage;
    m.ir_switch = model.ir_switch;
    m.ir_tempa_dec = model.ir_tempa_dec;
    m.ir_tempa_int = model.ir_tempa_int;
    m.ir_tempo_dec = model.ir_tempo_dec;
    m.ir_tempo_int = model.ir_tempo_int;
    m.temp_dec = model.temp_dec;
    m.temp_int = model.temp_int;
    m.time = [NSDate date];
    m.system_fan_rpm = [smcWrapper get_fan_rpm:0];
    m.system_cpu_temp = [smcWrapper get_maintemp];
    NSError *error = nil;
//    NSLog(@"%@ %d", m, [self isUpdateCompelete:model]);
    if ([self isUpdateCompelete:model] == YES) {
        return [_managedObjectContext save:&error];
    }else{
        [_managedObjectContext rollback];
        DDLogInfo(@"不能保存%@", error);
        return NO;
    }
}

- (void)resetAllDatas:(MKBLEDataModel *)model{
    model.ir_tempa_int = 255;
    model.ir_tempa_dec = 255;
    model.ir_tempo_int = 255;
    model.ir_tempo_dec = 255;
    model.ir_switch = 255;
    model.temp_int = 255;
    model.temp_dec = 255;
    model.fan_rpm = 255;
    model.fan_percentage = 255;
    model.auth_key = 255;
}

- (void)resetBLEDatas:(MKBLEDataModel *)model{
    model.ir_tempa_int = 255;
    model.ir_tempa_dec = 255;
    model.ir_tempo_int = 255;
    model.ir_tempo_dec = 255;
    model.ir_switch = 255;
    model.fan_rpm = 255;
    model.fan_percentage = 255;
}

- (BOOL)isUpdateCompelete:(MKBLEDataModel *)model{
    if (model.ir_tempa_int == 255) {
        return NO;
    }
    if (model.ir_tempa_dec == 255) {
        return NO;
    }
    if (model.ir_tempo_int == 255) {
        return NO;
    }
    if (model.ir_tempo_dec == 255) {
        return NO;
    }
    if (model.ir_switch == 255) {
        return NO;
    }
    if (model.fan_percentage == 255) {
        return NO;
    }
    if (model.fan_rpm == 255) {
        return NO;
    }
    return YES;
}

- (NSArray *)getRecentDatasWithNumber:(int)number{
    //创建查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BLEData"];
    //查询条件
//    NSPredicate *pre = [NSPredicate predicateWithFormat:@""];
//    request.predicate = pre;
    // 从第几页开始显示
    // 通过这个属性实现分页
    request.fetchOffset = 0;
    // 每页显示多少条数据
    request.fetchLimit = number;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    //发送查询请求
    NSArray *resArray = [controller.managedObjectContext executeFetchRequest:request error:nil];
    return resArray;
}

+ (instancetype)sharedSingleton{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 要使用self来调用
        controller = [[self alloc] init];
    });
    return controller;
}

- (instancetype)init{
    if (self = [super init]) {
        [self managedObjectContext];
    }
    return self;
}

@end
