//
//  UserLocation.h
//  PaxApp
//
//  Created by Junyuan Lau on 20/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface UserLocationAnnotation : NSObject<MKAnnotation>
{
	CLLocationCoordinate2D coordinate;	
	NSString *title;
	NSString *subTitle;
    NSNumber *driver_id;
    NSString *geoAddress;
}
@property (nonatomic,copy) NSString *subTitle;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,strong) NSString *geoAddress;

-(void)initWithCoordinate:(CLLocationCoordinate2D) c;
-(id)setCoordinateWithGV;
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;


@end
