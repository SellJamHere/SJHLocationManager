# SJHLocationManager

[![Version](https://img.shields.io/cocoapods/v/SJHLocationManager.svg?style=flat)](http://cocoadocs.org/docsets/SJHLocationManager)
[![License](https://img.shields.io/cocoapods/l/SJHLocationManager.svg?style=flat)](http://cocoadocs.org/docsets/SJHLocationManager)
[![Platform](https://img.shields.io/cocoapods/p/SJHLocationManager.svg?style=flat)](http://cocoadocs.org/docsets/SJHLocationManager)

The SJHLocationManager class implements a singleton subclass of CLLocationManager that utilizes location data to handle entering and exiting regions. Standard region handling works best for large regions, but is somewhat lacking when regions are small.

A few points to note in the [Apple Documentation](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html).

1. Monitoring of a region begins immediately after registration. However, do not expect to receive an event right away. Only boundary crossings can generate an event. Thus, if at registration time the user’s location is already inside the region, the location manager does not generate an event. Instead, you must wait for the user to cross the region boundary before an event is generated and sent to the delegate.
2. Specifically, the user’s location must cross the region boundary, move away from the boundary by a minimum distance, and remain at that minimum distance for at least 20 seconds before the notifications are reported.
3. You can assume that the minimum distance is approximately 200 meters.
4. An app can expect to receive the appropriate region entered or region exited notification within 3 to 5 minutes on average, if not sooner.

To facilitate a more accurate region monitoring, any regions added for monitoring are checked each time the location is updated. To facilitate timely region updates, an `NSTimer` is scheduled. The interval is determined by `SJHLocationManager`'s setTimerInterval: method. 

## CLLocationManagerDelegate

|     One-to-One        |  One-to-Many  |
|:-----------------:    |:------------: |
| Protocol/Delegate     | Notification  |

When location events occur, they can be forwarded to one class through the delegate or broadcast through ```NSNotificationCenter```. 

SJHLocationManager implements CLLocationManagerDelegate methods. If ```SJHLocationManager.delegate``` is set, its appropriate methods are called. Otherwise notifications are posted to ```[NSNotificationCenter defaultCenter]``` when delegate methods are called, using the appropriate notification name constant.
 
Notifications are received with:
 
```objective-c
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFinishedHandler:) name:kLocationManagerDidUpdateLocation object:nil];
```

## Installation

SJHLocationManager is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

    pod "SJHLocationManager"

## Development Notes

Currently, only CLCircularRegion objects are supported for region tracking. 

## Author

James Heller, jaheller5@gmail.com

## License

SJHLocationManager is available under the MIT license. See the LICENSE file for more info.

