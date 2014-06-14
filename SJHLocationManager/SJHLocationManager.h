#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

/***************************************************************************************
 *
 * Notifications are posted to [NSNotificationCenter defaultCenter] on location update
 *
 * They can be received with:
 * [[NSNotificationCenter defaultCenter] addObserver:self 
 *                                          selector:@selector(requestFinishedHandler:)
 *                                              name:kDidUpdateLocation
 *                                            object:nil];
 *
 ***************************************************************************************/

extern NSString * const kLocationManagerDidUpdateLocation;
extern NSString * const kLocationManagerDidFailWithError;
extern NSString * const kLocationManagerDidEnterRegion;
extern NSString * const kLocationManagerDidExitRegion;
extern NSString * const kLocationManagerMonitoringDidFailForRegion;

extern const CLLocationAccuracy kDefaultLocationAccuracy;
extern const NSTimeInterval kLocationTimerIntervalDefault;

@interface SJHLocationManager : CLLocationManager

+ (instancetype)sharedInstance;

- (void)setTimerInterval:(NSTimeInterval)interval;

@end
