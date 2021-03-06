//
//  OtherQuery.m
//  PaxApp
//
//  Created by Junyuan Lau on 31/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OtherQuery.h"
#import "Constants.h"

@implementation OtherQuery

//decomm
+ (void) getFareWithlocation:(CLLocationCoordinate2D)location destination:(CLLocationCoordinate2D) destination taxitype:(NSString*)taxitype completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{   
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];

    NSString* postBody = [[NSString alloc] initWithFormat:@"pickup_latitude=%f&pickup_longitude=%f&destination_latitude=%f&destination_longitude=%f&taxi_type=%@",location.latitude, location.longitude, destination.latitude, destination.longitude,taxitype];

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@jobs/fare?auth_token=%@",kHerokuHostSite,[preferences objectForKey:@"ClientAuth"]]]];    
    NSData *postData = [postBody dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];     
    
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler]; 
}

//done
+ (void) getFareWithDictionary:(NSDictionary*)dictdata completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{   
    NSLog(@"%@ - %@ - %@",self.class,NSStringFromSelector(_cmd),dictdata);

    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* maindict = [[NSMutableDictionary alloc]init];
    [maindict setObject:dictdata forKey:@"job"];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:maindict options:0 error:nil];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
   
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@jobs/fare?auth_token=%@",kHerokuHostSite,[preferences objectForKey:@"ClientAuth"]]]];    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];

    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler]; 
}

//not in use yet
+ (void) getNearestTimeWithlocation:(CLLocationCoordinate2D)location completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    
    //NSString* getString = [[NSString alloc] initWithFormat:@"latitude=%f&longitude=%f",location.latitude, location.longitude];
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
    //NSData *getData = [getString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];     
    //NSString *getLength = [NSString stringWithFormat:@"%d", [getData length]];

    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@drivers/nearest?auth_token=%@",kHerokuHostSite,[preferences objectForKey:@"ClientAuth"]]]];    
    [request setHTTPMethod:@"GET"];
    //[request setValue:getLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    //[request setHTTPBody:getData];
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler];

}

//done
+ (void) registerWithEmail:(NSString*)email password:(NSString*)password name:(NSString*)name mobile:(NSString*) mobile_number completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    NSLog(@"%@ - %@",self.class,NSStringFromSelector(_cmd));
    NSMutableDictionary* maindict = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* dictdata = [[NSMutableDictionary alloc]init];

    [dictdata setObject:email forKey:@"email"];
    [dictdata setObject:mobile_number forKey:@"mobile_number"];
    [dictdata setObject:name forKey:@"name"];
    [dictdata setObject:password forKey:@"password"];
    [dictdata setObject:password forKey:@"password_confirmation"];
    [maindict setObject:dictdata forKey:@"passenger"];
    NSData* postData = [NSJSONSerialization dataWithJSONObject:maindict options:0 error:nil];

    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];  
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@register",kHerokuHostSite]]]; 
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler];
}

//done
+ (void) logInWithEmail:(NSString*)email password:(NSString*)password deviceID:(NSString*)deviceID completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    
    NSLog(@"%@ - %@ - %@ - %@",self.class,NSStringFromSelector(_cmd), email, password);
    NSMutableDictionary* maindict = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* dictdata = [[NSMutableDictionary alloc]init];
    
    [dictdata setObject:email forKey:@"email"];
    [dictdata setObject:password forKey:@"password"];
    [dictdata setObject:deviceID forKey:@"device_token"];
    [dictdata setObject:@"ios" forKey:@"platform"];
    
    [maindict setObject:dictdata forKey:@"passenger"];

    NSData* postData = [NSJSONSerialization dataWithJSONObject:maindict options:0 error:nil];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];  
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@login",kHerokuHostSite]]]; 
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //[request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler];
    /*
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval: TimeOutSecond
                                                     target: self
                                                selector: @selector()
                                                   userInfo: nil
                                                    repeats: NO];
*/
}

//done
+ (void) getMyTripscompletionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@profile/trips?auth_token=%@",kHerokuHostSite,[preferences objectForKey:@"ClientAuth"]]]];    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler];
}


//done
+ (void) reviewJobID:(NSString*)job_id review:(int)review feedback:(NSString*) feedback completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];

    
    NSLog(@"%@ - %@",self.class,NSStringFromSelector(_cmd));
    NSString* postBody = [[NSString alloc] initWithFormat:@"review=%i&feedback=%@",review, feedback];
    NSData *postData = [postBody dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];     // postData format - @"key=value&key2=value2"
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];  
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@jobs/%@/review?auth_token=%@", kHerokuHostSite,job_id, [preferences objectForKey:@"ClientAuth"]]]]; 
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[[NSOperationQueue alloc] init] 
                           completionHandler:handler];
}

+ (void) updateProfileWithEmail:(NSString*)email password:(NSString*)password name:(NSString*)name mobile:(NSString*) mobile_number completionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];

    NSLog(@"%@ - %@",self.class,NSStringFromSelector(_cmd));
    NSMutableDictionary* maindict = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* dictdata = [[NSMutableDictionary alloc]init];

    [dictdata setObject:email forKey:@"email"];
    [dictdata setObject:mobile_number forKey:@"mobile_number"];
    [dictdata setObject:name forKey:@"name"];
    [dictdata setObject:password forKey:@"password"];
    [maindict setObject:dictdata forKey:@"passenger"];
    NSData* postData = [NSJSONSerialization dataWithJSONObject:maindict options:0 error:nil];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@profile?auth_token=%@",kHerokuHostSite,[preferences objectForKey:@"ClientAuth"]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:handler];
}

//done
+ (void) getVersioncompletionHandler:(void (^) (NSURLResponse* response, NSData* data, NSError *error))handler
{
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@version",kHerokuHostSite]]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:kURLConnTimeOut];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:handler];
}


@end
