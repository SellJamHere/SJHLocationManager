
#import <Foundation/Foundation.h>
#import <CoreLocation/CLRegion.h>

/**
 `SSRegionWrapper` wraps a `CLRegion` with a boolean flag to track whether the the device is currently in the region.
 */
@interface SSRegionWrapper : NSObject

/**
 `region` is the region added to `SJHLocationManager` for monitoring.
 */
@property (strong, nonatomic) CLRegion *region;

/**
 `isInsideRegion` is YES when the last checked user location is inside the region, and NO otherwise.
 */
@property BOOL isInsideRegion;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns an `SSRegionWrapper` object.
 */
- (instancetype) initWithRegion:(CLRegion *)region;

@end