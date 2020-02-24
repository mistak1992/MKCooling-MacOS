//
//  MKBLEDataPresistModel+CoreDataProperties.m
//  mkcooling
//
//  Created by mist on 2019/10/22.
//  Copyright © 2019 mistak1992. All rights reserved.
//
//

#import "MKBLEDataPresistModel+CoreDataProperties.h"

@implementation MKBLEDataPresistModel (CoreDataProperties)

+ (NSFetchRequest<MKBLEDataPresistModel *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BLEData"];
}

@dynamic system_fan_rpm;
@dynamic system_cpu_temp;
@dynamic auth_key;
@dynamic fan_percentage;
@dynamic fan_rpm;
@dynamic pid;
@dynamic ir_switch;
@dynamic ir_tempa_dec;
@dynamic ir_tempa_int;
@dynamic ir_tempo_dec;
@dynamic ir_tempo_int;
@dynamic temp_dec;
@dynamic temp_int;
@dynamic time;

@end
