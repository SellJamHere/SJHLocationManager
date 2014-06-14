
#import "SJHLocationHandler.h"

#import <CoreLocation/CoreLocation.h>

#import "SJHLocationManager.h"

@implementation SJHLocationHandler

+ (void)initInstance {
    [[self class] sharedInstance];
}

+ (instancetype)sharedInstance {
    static SJHLocationHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        SJHLocationManager *locationManager = [SJHLocationManager sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:kLocationManagerDidUpdateLocation object:locationManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailLocationUpdateWithError:) name:kLocationManagerDidFailWithError object:locationManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterRegion:) name:kLocationManagerDidEnterRegion object:locationManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExitRegion:) name:kLocationManagerDidExitRegion object:locationManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailMonitoringForRegionWithError:) name:kLocationManagerMonitoringDidFailForRegion object:locationManager];
    }
    return self;
}

#pragma mark - Location Notification selectors
- (void)didUpdateLocation:(NSNotification *)notification {
    NSLog(@"Notification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    CLLocation *location = userInfo[@"location"];
    NSLog(@"Location: %@", location);
}

- (void)didFailLocationUpdateWithError:(NSNotification *)notification {
    NSLog(@"Notification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    NSError *error = userInfo[@"error"];
    NSLog(@"Error: %@", error);
}

- (void)didEnterRegion:(NSNotification *)notification {
    NSLog(@"Notification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    CLRegion *region = userInfo[@"region"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Entered Region" message:[region identifier] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)didExitRegion:(NSNotification *)notification {
    NSLog(@"Notification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    CLRegion *region = userInfo[@"region"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exited Region" message:[region identifier] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)didFailMonitoringForRegionWithError:(NSNotification *)notification {
    NSLog(@"Notification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    CLRegion *region = userInfo[@"region"];
    NSError *error = userInfo[@"error"];
    NSLog(@"Region: %@", region);
    NSLog(@"Error: %@", error);
}

#pragma mark - Geofence methods
- (void)addGeofenceRegion:(CLRegion *)region {
    [[SJHLocationManager sharedInstance] startMonitoringForRegion:region];
}

- (void)removeGeofenceRegion:(CLRegion *)region {
    [[SJHLocationManager sharedInstance] stopMonitoringForRegion:region];
}

@end
