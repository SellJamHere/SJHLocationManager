//
//  SSLocationSingleton.m
//  SoulSoupConsumer
//
//  Created by James Heller on 5/13/14.
//  Copyright (c) 2014 SoulSoup. All rights reserved.
//

#import "SJHLocationManager.h"

#import "SJHRegionWrapper.h"

NSString * const kLocationManagerDidUpdateLocation = @"LocationManagerDidUpdateLocation";
NSString * const kLocationManagerDidFailWithError = @"LocationManagerDidFailWithError";
NSString * const kLocationManagerDidEnterRegion = @"LocationManagerDidEnterRegion";
NSString * const kLocationManagerDidExitRegion = @"LocationManagerDidExitRegion";
NSString * const kLocationManagerMonitoringDidFailForRegion = @"LocationManagerMonitoringDidFailForRegion";

const CLLocationAccuracy kDefaultLocationAccuracy = 50.0;
const NSTimeInterval kLocationTimerIntervalDefault = 300.0;

/*
 * BOOL isUpdatingLocations
 * BOOL isMonitoringRegions
 *
 * Used to determine which delegate methods are called. Regions are checked by
 * updating location, but if no one asked for location to be updated, we shouldn't
 * send the updates to the update location delegate methods for notification.
 *
 */

@interface SJHLocationManager () <CLLocationManagerDelegate>

@property (atomic) BOOL isUpdatingLocation;

@property (strong, nonatomic) NSMutableSet *regionSet;
@property (strong, nonatomic) NSTimer *regionTimer;
@property NSTimeInterval regionTimerInterval;

@end

@implementation SJHLocationManager

+ (instancetype)sharedInstance {
    static SJHLocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.isUpdatingLocation = NO;
        
        self.regionSet = [[NSMutableSet alloc] init];
        self.regionTimerInterval = kLocationTimerIntervalDefault;
    }
    return self;
}

#pragma mark - Timer Methods
- (void)startRegionTimer {
    self.regionTimer = [NSTimer scheduledTimerWithTimeInterval:self.regionTimerInterval target:self selector:@selector(startUpdatingLocation) userInfo:nil repeats:YES];
}

- (void)stopRegionTimer {
    [self.regionTimer invalidate];
    self.regionTimer = nil;
}

- (void)setTimerInterval:(NSTimeInterval)interval {
    self.regionTimerInterval = interval;
    if (self.regionTimer) {
        [self stopRegionTimer];
        [self startRegionTimer];
    }
}

#pragma mark - Location Methods
- (BOOL)isAuthorizedForLocationServices {
    return [CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized;
}

- (BOOL)shouldstartLocationMonitoring {
    return self.isUpdatingLocation || [self.regionSet count] > 0 || self.regionTimer;
}

- (void)startUpdatingLocation {
    if ([self isAuthorizedForLocationServices]) {
        self.isUpdatingLocation = YES;
        [super startUpdatingLocation];
    }
    else {
        NSLog(@"Location services are disabled, or denied authorization");
    }
}

- (void)stopUpdatingLocation {
    if ([self isAuthorizedForLocationServices]) {
        self.isUpdatingLocation = NO;
        if ([self.regionSet count] == 0) {
            [super stopUpdatingLocation];
        }
    }
    else {
        NSLog(@"Location services are disabled, or denied authorization");
    }
}

//kick off location monitoring every 5 minutes to get a location and
//determine if the region is in bounds
//set isMonitoringRegions to true
- (void)startMonitoringForRegion:(CLRegion *)region {
    if ([self isAuthorizedForLocationServices] && [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        if ([region isKindOfClass:[CLCircularRegion class]]) {

            SSRegionWrapper *regionWrapper = [[SSRegionWrapper alloc] initWithRegion:region];
            regionWrapper.isInsideRegion = [(CLCircularRegion *)region containsCoordinate:self.location.coordinate];
            if (regionWrapper.isInsideRegion) {
                [self locationManager:self didEnterRegion:regionWrapper.region];
            }
            else {
                [self locationManager:self didExitRegion:regionWrapper.region];
            }
            [self.regionSet addObject:regionWrapper];
            
            [super startMonitoringForRegion:region];
            [super startUpdatingLocation];
            [self startRegionTimer];
        }
    }
    else {
        NSLog(@"Location services are disabled, or denied authorization");
    }
}

//set isMonitoringRegions to false
- (void)stopMonitoringForRegion:(CLRegion *)region {
    if ([self isAuthorizedForLocationServices]) {
        //remove region from self.regionSet
        NSSet *specifiedRegions = [self.regionSet objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            return [[[(SSRegionWrapper *)obj region] identifier] isEqualToString:region.identifier];
        }];
        for (SSRegionWrapper *wrapper in specifiedRegions) {
            [self.regionSet removeObject:wrapper];
        }
        if ([self.regionSet count] == 0) {
            [self stopRegionTimer];
        }
        
        [super stopMonitoringForRegion:region];
    }
    else {
        NSLog(@"Location services are disabled, or denied authorization");
    }
}

- (void)sendRegionNotifications {
    for (SSRegionWrapper *wrapper in self.regionSet) {
        if ([wrapper.region isKindOfClass:[CLCircularRegion class]]) {
//            NSLog(@"\nRegion Center: <%f, %f>, Radius: %f\nLocation: <%f, %f>\nRegion contains location: %@\n\n\n\n", [(CLCircularRegion *)[wrapper region] center].latitude, [(CLCircularRegion *)[wrapper region] center].longitude, [(CLCircularRegion *)[wrapper region] radius], self.location.coordinate.latitude, self.location.coordinate.longitude, ([(CLCircularRegion *)[wrapper region] containsCoordinate:self.location.coordinate] ? @"YES" : @"NO"));
            if ([(CLCircularRegion *)wrapper.region containsCoordinate:self.location.coordinate]) {
                if (!wrapper.isInsideRegion) {
                    wrapper.isInsideRegion = YES;
                    [self locationManager:self didEnterRegion:wrapper.region];
                }
            }
            else {
                if (wrapper.isInsideRegion) {
                    wrapper.isInsideRegion = NO;
                    [self locationManager:self didExitRegion:wrapper.region];
                }
            }
        }
    }
    [super stopUpdatingLocation];
}

#pragma mark - location delegate methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    
    if ([self shouldstartLocationMonitoring] && [location horizontalAccuracy] <= [self desiredAccuracy]) {
        [self stopUpdatingLocation];
        NSLog(@"Location updated: %@", location);
        if (self.isUpdatingLocation) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateLocation object:self userInfo:@{@"location": location}];
        }
        if ([self.regionSet count] > 0) {
            [self sendRegionNotifications];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error: %@", [error localizedDescription]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidFailWithError object:self userInfo:@{@"error": error}];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered region: %@", region);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidEnterRegion object:self userInfo:@{@"region": region}];
    [super stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited region: %@", region);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidExitRegion object:self userInfo:@{@"region": region}];
    [super stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Monitoring did fail for region: %@, with error: %@", region, error);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerMonitoringDidFailForRegion object:self userInfo:@{@"region": region, @"error": error}];
}

@end
