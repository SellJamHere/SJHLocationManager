//
//  SSLocationSingleton.m
//  SoulSoupConsumer
//
//  Created by James Heller on 5/13/14.
//  Copyright (c) 2014 SoulSoup. All rights reserved.
//

#import "SJHLocationManager.h"
#import "SJHRegionWrapper.h"

#define DELEGATE_DEBUG 0

//Responding to Location Events
NSString * const kLocationManagerDidUpdateLocations = @"LocationManagerDidUpdateLocation";
NSString * const kLocationManagerDidFailWithError = @"LocationManagerDidFailWithError";
NSString * const kLocationManagerDidFinishDeferredUpdatesWithError = @"LocationManagerDidFinishDeferredUpdatesWithError";
//Pausing Location Updates
NSString * const kLocationManagerDidPauseLocationUpdates = @"LocationManagerDidPauseLocationUpdates";
NSString * const kLocationManagerDidResumeLocationUpdates = @"LocationManagerDidResumeLocationUpdates";
//Responding to Heading Events
NSString * const kLocationManagerDidUpdateHeading = @"LocationManagerDidUpdateHeading";
//Responding to Region Events
NSString * const kLocationManagerDidEnterRegion = @"LocationManagerDidEnterRegion";
NSString * const kLocationManagerDidExitRegion = @"LocationManagerDidExitRegion";
NSString * const kLocationManagerDidDetermineStateForRegion = @"LocationManagerDidDetermineStateForRegion";
NSString * const kLocationManagerMonitoringDidFailForRegion = @"LocationManagerMonitoringDidFailForRegion";
NSString * const kLocationManagerDidStartMonitoringForRegion = @"LocationManagerDidStartMonitoringForRegion";
//Responding to Ranging Events
NSString * const kLocationManagerDidRangeBeaconsInRegion = @"LocationManagerDidRangeBeaconsInRegion";
NSString * const kLocationManagerRangingBeaconsDidFailForRegion = @"LocationManagerRangingBeaconsDidFailForRegion";
//Responding to Authorization Changes
NSString * const kLocationManagerDidChangeAuthorizationStatus = @"LocationManagerDidChangeAuthorizationStatus";

const CLLocationAccuracy kDefaultLocationAccuracy = 50.0;
const NSTimeInterval kLocationTimerIntervalDefault = 300.0;

@interface SJHLocationManager () <CLLocationManagerDelegate> {
    id<CLLocationManagerDelegate> _externalDelegate;
    NSTimeInterval _regionTimerInterval;
}

@property (atomic) BOOL isUpdatingLocation;

@property (strong, nonatomic) NSMutableSet *regionSet;
@property (strong, nonatomic) NSTimer *regionTimer;

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
        [super setDelegate: self];
        self.isUpdatingLocation = NO;
        self.shouldDisplayHeadingCalibration = NO;
        
        self.regionSet = [[NSMutableSet alloc] init];
        self.regionTimerInterval = kLocationTimerIntervalDefault;
    }
    return self;
}

#pragma mark - Override delegate property methods
- (void)setDelegate:(id<CLLocationManagerDelegate>)delegate {
    _externalDelegate = delegate;
}

- (id<CLLocationManagerDelegate>)delegate {
    return _externalDelegate;
}

#pragma mark - Timer Methods
- (void)startRegionTimer {
    self.regionTimer = [NSTimer scheduledTimerWithTimeInterval:_regionTimerInterval target:self selector:@selector(startUpdatingLocation) userInfo:nil repeats:YES];
}

- (void)stopRegionTimer {
    [self.regionTimer invalidate];
    self.regionTimer = nil;
}

- (void)setRegionTimerInterval:(NSTimeInterval)interval {
    _regionTimerInterval = interval;
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

- (void)startMonitoringForRegion:(CLRegion *)region {
    if ([self isAuthorizedForLocationServices] && [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        if ([region isKindOfClass:[CLCircularRegion class]]) {

            SSRegionWrapper *regionWrapper = [[SSRegionWrapper alloc] initWithRegion:region];
            regionWrapper.isInsideRegion = [(CLCircularRegion *)region containsCoordinate:self.location.coordinate];
            if (regionWrapper.isInsideRegion) {
                [self.delegate locationManager:self didEnterRegion:regionWrapper.region];
            }
            else {
                [self.delegate locationManager:self didExitRegion:regionWrapper.region];
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
#if DELEGATE_DEBUG
    NSLog(@"\nRegion Center: <%f, %f>, Radius: %f\nLocation: <%f, %f>\nRegion contains location: %@\n\n\n\n", [(CLCircularRegion *)[wrapper region] center].latitude, [(CLCircularRegion *)[wrapper region] center].longitude, [(CLCircularRegion *)[wrapper region] radius], self.location.coordinate.latitude, self.location.coordinate.longitude, ([(CLCircularRegion *)[wrapper region] containsCoordinate:self.location.coordinate] ? @"YES" : @"NO"));
#endif
            if ([(CLCircularRegion *)wrapper.region containsCoordinate:self.location.coordinate]) {
                if (!wrapper.isInsideRegion) {
                    wrapper.isInsideRegion = YES;
                    [self.delegate locationManager:self didEnterRegion:wrapper.region];
                }
            }
            else {
                if (wrapper.isInsideRegion) {
                    wrapper.isInsideRegion = NO;
                    [self.delegate locationManager:self didExitRegion:wrapper.region];
                }
            }
        }
    }
    [super stopUpdatingLocation];
}

#pragma mark - location delegate methods
//Responding to Location Events
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    
    if ([self shouldstartLocationMonitoring] && [location horizontalAccuracy] <= [self desiredAccuracy]) {
        [self stopUpdatingLocation];
#if DELEGATE_DEBUG
    NSLog(@"Location updated: %@", location);
#endif
        if (self.isUpdatingLocation) {
            if (_externalDelegate != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateLocations object:self userInfo:@{@"location": location}];
            }
            else {
                [_externalDelegate locationManager:manager didUpdateLocations:locations];
            }
        }
        if ([self.regionSet count] > 0) {
            [self sendRegionNotifications];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
#if DELEGATE_DEBUG
    NSLog(@"Location manager failed with error: %@", [error localizedDescription]);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidFailWithError object:self userInfo:@{@"error": error}];
    }
    else {
        [_externalDelegate locationManager:manager didFailWithError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did finish deferred updates with error: %@", [error localizedDescription]);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidFinishDeferredUpdatesWithError object:self userInfo:@{@"error": error}];
    }
    else {
        [_externalDelegate locationManager:manager didFinishDeferredUpdatesWithError:error];
    }
}

//Pausing Location Updates
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did pause location updates");
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidPauseLocationUpdates object:self userInfo:nil];
    }
    else {
        [_externalDelegate locationManagerDidPauseLocationUpdates:manager];
    }
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did resume location updates");
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidResumeLocationUpdates object:self userInfo:nil];
    }
    else {
        [_externalDelegate locationManagerDidResumeLocationUpdates:manager];
    }
}

//Responding to Heading Events
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did update heading: %@", newHeading);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateHeading object:self userInfo:@{@"heading": newHeading}];
    }
    else {
        [_externalDelegate locationManager:manager didUpdateHeading:newHeading];
    }
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
#if DELEGATE_DEBUG
    NSLog(@"Location manager should display heading calibration. Should Calibrate: %@", (self.shouldDisplayHeadingCalibration ? @"YES" : @"NO"));
#endif
    if (_externalDelegate == nil) {
        return self.shouldDisplayHeadingCalibration;
    }
    else {
        return [_externalDelegate locationManagerShouldDisplayHeadingCalibration:manager];
    }
}

//Responding to Region Events
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
#if DELEGATE_DEBUG
    NSLog(@"Entered region: %@", region);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidEnterRegion object:self userInfo:@{@"region": region}];
    }
    else {
        [_externalDelegate locationManager:manager didEnterRegion:region];
    }
    [super stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
#if DELEGATE_DEBUG
    NSLog(@"Exited region: %@", region);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidExitRegion object:self userInfo:@{@"region": region}];
    }
    else {
        [_externalDelegate locationManager:manager didExitRegion:region];
    }
    [super stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
#if DELEGATE_DEBUG
    NSLog(@"Did determine state: %@ for region: %@", [NSNumber numberWithInteger:state], region);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidDetermineStateForRegion object:self userInfo:@{@"state": [NSNumber numberWithInteger:state], @"region": region}];
    }
    else {
        [_externalDelegate locationManager:manager didExitRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
#if DELEGATE_DEBUG
    NSLog(@"Monitoring did fail for region: %@, with error: %@", region, error);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerMonitoringDidFailForRegion object:self userInfo:@{@"region": region, @"error": error}];
    }
    else {
        [_externalDelegate locationManager:manager monitoringDidFailForRegion:region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did start monitoring for region: %@", region);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidStartMonitoringForRegion object:self userInfo:@{@"region": region}];
    }
    else {
        [_externalDelegate locationManager:manager didStartMonitoringForRegion:region];
    }
}

//Responding to Ranging Events
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did range beacons: %@ in region: %@", beacons, region);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidRangeBeaconsInRegion object:self userInfo:@{@"beacons": beacons, @"region": region}];
    }
    else {
        [_externalDelegate locationManager:manager didRangeBeacons:beacons inRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
#if DELEGATE_DEBUG
    NSLog(@"Location manager ranging beacons did fail for region: %@ with error: %@", region, [error localizedDescription]);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerRangingBeaconsDidFailForRegion object:self userInfo:@{@"region": region, @"error": error}];
    }
    else {
        [_externalDelegate locationManager:manager rangingBeaconsDidFailForRegion:region withError:error];
    }
}

//Responding to Authorization Changes
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
#if DELEGATE_DEBUG
    NSLog(@"Location manager did change authorization status: %@", [NSNumber numberWithInteger:status]);
#endif
    if (_externalDelegate == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidChangeAuthorizationStatus object:self userInfo:@{@"status": [NSNumber numberWithInteger:status]}];
    }
    else {
        [_externalDelegate locationManager:manager didChangeAuthorizationStatus:status];
    }
}

@end
