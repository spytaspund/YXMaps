//
//  gps.m
//  YXMaps
//
//  Created by spytaspund on 25.07.2026.
//
// i HATE iOS 6!!!!!!!!!!!!

#import "gps.h"
#import <CoreLocation/CoreLocation.h>

@interface gps () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationMgr;
@property (nonatomic, assign) double lastLat;
@property (nonatomic, assign) double lastLon;
@end

@implementation gps

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationMgr = [[CLLocationManager alloc] init];
        _locationMgr.delegate = self;
        _locationMgr.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

- (void)startTracking {
    if ([self.locationMgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationMgr performSelector:@selector(requestWhenInUseAuthorization)];
    }
    
    [self.locationMgr startUpdatingLocation];
}

- (void)stopTracking {
    [self.locationMgr stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    if (!location) return;
    
    self.lastLat = location.coordinate.latitude;
    self.lastLon = location.coordinate.longitude;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didUpdateLocationLat:lon:)]) {
            [self.delegate didUpdateLocationLat:self.lastLat lon:self.lastLon];
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didFailWithError:)]) {
            [self.delegate didFailWithError:error];
        }
    });
}

@end
