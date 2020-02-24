//
//  MKBLEDataPresistModel+CoreDataProperties.h
//  mkcooling
//
//  Created by mist on 2019/10/22.
//  Copyright © 2019 mistak1992. All rights reserved.
//
//

#import "MKBLEDataPresistModel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MKBLEDataPresistModel (CoreDataProperties)

+ (NSFetchRequest<MKBLEDataPresistModel *> *)fetchRequest;

@property (nonatomic) int64_t auth_key;
@property (nonatomic) int64_t fan_percentage;
@property (nonatomic) int64_t fan_rpm;
@property (nonatomic) int64_t pid;
@property (nonatomic) int64_t ir_switch;
@property (nonatomic) int64_t ir_tempa_dec;
@property (nonatomic) int64_t ir_tempa_int;
@property (nonatomic) int64_t ir_tempo_dec;
@property (nonatomic) int64_t ir_tempo_int;
@property (nonatomic) int64_t temp_dec;
@property (nonatomic) int64_t temp_int;
@property (nonatomic) CGFloat system_cpu_temp;
@property (nonatomic) int64_t system_fan_rpm;
@property (nullable, nonatomic, copy) NSDate *time;

@end

NS_ASSUME_NONNULL_END
