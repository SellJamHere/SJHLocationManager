//
//  SSRegionWrapper.m
//  SoulSoupConsumer
//
//  Created by James Heller on 6/5/14.
//  Copyright (c) 2014 SoulSoup. All rights reserved.
//

#import "SJHRegionWrapper.h"

@implementation SSRegionWrapper

- (instancetype) init {
    self = [self initWithRegion:nil];
    return self;
}

- (instancetype) initWithRegion:(CLRegion *)region {
    self = [super init];
    if (self) {
        self.region = region;
        self.isInsideRegion = NO;
    }
    return self;
}

@end
