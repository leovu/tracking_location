#import "TrackingLocationPlugin.h"
#if __has_include(<tracking_location/tracking_location-Swift.h>)
#import <tracking_location/tracking_location-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "tracking_location-Swift.h"
#endif

@implementation TrackingLocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTrackingLocationPlugin registerWithRegistrar:registrar];
}
@end
