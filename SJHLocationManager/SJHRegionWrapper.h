//
//  SSRegionWrapper.h
//  SoulSoupConsumer
//
//  Created by James Heller on 6/5/14.
//  Copyright (c) 2014 SoulSoup. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CLRegion.h>

@interface SSRegionWrapper : NSObject

@property (strong, nonatomic) CLRegion *region;
@property BOOL isInsideRegion;

- (instancetype) initWithRegion:(CLRegion *)region;

@end