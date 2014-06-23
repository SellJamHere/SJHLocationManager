#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

/***************************************************************************************
 *
 * 
 *
 * /////////////////////////////////////////////////////////////////////////////////////
 * Notifications are posted to [NSNotificationCenter defaultCenter] on location update
 *
 * They can be received with:
 * [[NSNotificationCenter defaultCenter] addObserver:self 
 *                                          selector:@selector(requestFinishedHandler:)
 *                                              name:kLocationManagerDidUpdateLocation
 *                                            object:nil];
 *
 ***************************************************************************************/

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

+ (instancetype)sharedInstance;

- (void)setTimerInterval:(NSTimeInterval)interval;
- (void)setCalibrationFlag:(BOOL)calibrationFlag;

@end
