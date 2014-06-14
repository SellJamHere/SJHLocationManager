
#import <Foundation/Foundation.h>

#import <CoreLocation/CLRegion.h>

@interface SJHLocationHandler : NSObject

+ (void)initInstance;
+ (instancetype)sharedInstance;

- (void)addGeofenceRegion:(CLRegion *)region;
- (void)removeGeofenceRegion:(CLRegion *)region;

@end
