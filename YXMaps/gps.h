//
//  gps.h
//  YXMaps
//
//  Created by spytaspund on 25.07.2026.
//
// i HATE iOS 6!!!!!!!!!!!!

#ifndef gps_h
#define gps_h

#import <Foundation/Foundation.h>


@protocol gpsDelegate <NSObject>
@optional
- (void)didUpdateLocationLat:(double)lat lon:(double)lon;
- (void)didFailWithError:(NSError *)error;
@end

@interface gps : NSObject

@property (nonatomic, weak) id<gpsDelegate> delegate;

- (void)startTracking;
- (void)stopTracking;

@end

#endif /* gps_h */
