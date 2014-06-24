
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 `SJHLocationManager` implements `CLLocationManagerDelegate` methods. If `SJHLocationManager.delegate` is set, its appropriate methods are called. Otherwise notifications are posted to `[NSNotificationCenter defaultCenter]` when delegate methods are called, using the appropriate notification name constant.
 
 Notifications are received with:
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFinishedHandler:) name:kLocationManagerDidUpdateLocation object:nil];
 
 */

//Responding to Location Events
extern NSString * const kLocationManagerDidUpdateLocations;
extern NSString * const kLocationManagerDidFailWithError;
extern NSString * const kLocationManagerDidFinishDeferredUpdatesWithError;
//Pausing Location Updates
extern NSString * const kLocationManagerDidPauseLocationUpdates;
extern NSString * const kLocationManagerDidResumeLocationUpdates;
//Responding to Heading Events
extern NSString * const kLocationManagerDidUpdateHeading;
//Responding to Region Events
extern NSString * const kLocationManagerDidEnterRegion;
extern NSString * const kLocationManagerDidExitRegion;
extern NSString * const kLocationManagerDidDetermineStateForRegion;
extern NSString * const kLocationManagerMonitoringDidFailForRegion;
extern NSString * const kLocationManagerDidStartMonitoringForRegion;
//Responding to Ranging Events
extern NSString * const kLocationManagerDidRangeBeaconsInRegion;
extern NSString * const kLocationManagerRangingBeaconsDidFailForRegion;
//Responding to Authorization Changes
extern NSString * const kLocationManagerDidChangeAuthorizationStatus;

extern const CLLocationAccuracy kDefaultLocationAccuracy;
extern const NSTimeInterval kLocationTimerIntervalDefault;

@interface SJHLocationManager : CLLocationManager

/**
 Boolean flag used for locationManagerShouldDisplayHeadingCalibration: delegate calls.
 Defaults to NO.
 */
@property BOOL shouldDisplayHeadingCalibration;

/// ----------------------
/// @name Singleton Object
/// ----------------------

/**
 Returns an `SJHLocationManager` singleton.
 */
+ (instancetype)sharedInstance;


/**
 Sets the interval at which location updates will be requested for region monitoring.
 */
- (void)setRegionTimerInterval:(NSTimeInterval)interval;

@end
