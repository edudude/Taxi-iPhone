//
//  ViewController.m
//  PaxApp
//
//  Created by Junyuan Lau on 20/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainMapViewController.h"
#import "DriverPositionPoller.h"
#import "GlobalVariables.h"
#import "UserLocationAnnotation.h"
#import "CoreLocationManager.h"
#import "GetGeocodedAddress.h"
#import "CustomNavBar.h"
#import "OtherQuery.h"
#import "Toast+UIView.h"
#import "ActivityProgressView.h"


static NSString* apiKey = @"AIzaSyCqe57ih20Bt7X26dk1vFgatymmmxyS9VI";


@implementation MainMapViewController
@synthesize mapView, dirty, loading, suggestions, references;

#pragma mark Initialisation
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //If active job is present and goto SubmitJob VC
     if ([[GlobalVariables myGlobalVariables] gGoto]){
        [self performSegueWithIdentifier:@"gotoSubmitJob" sender:self];
        NSLog(@"%@ - %@ - Goto Submit Job",self.class,NSStringFromSelector(_cmd));
        return;
    }
    
    [mapView setDelegate:self];
    
    
    [self registerNotification];
    downloader = [[DriverPositionPoller alloc]initDriverPositionPollWithDriverID:[NSString stringWithFormat:@"all"]];    
    [self getUserLocation];    
    
    //set top navBar
    CustomNavBar *thisNavBar = [[CustomNavBar alloc] initOneRowBar];    
    self.navigationItem.titleView = thisNavBar;
    [thisNavBar setCustomNavBarTitle:NSLocalizedString(@"Current Location", @"") subtitle:@""];
    [thisNavBar addRightLogo];
    self.navigationItem.hidesBackButton = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    self.tabBarController.delegate = self;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    //clear global variables
    [[GlobalVariables myGlobalVariables] clearGlobalData];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{

    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    // stop downloading driver position
    [downloader stopDriverPositionPoll];
    
    //remove notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [clManager stopUpdating];
    //clear annotations list
    newDriverList = nil;
    oldDriverList = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMapMarkers:) name:@"driverListUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserMarker:) name:@"userLocationUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateETA:) name:@"ETA" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGeoAddress:) name:@"GeoAddress" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showActivityView:) name:@"showProgressActivity" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideActivityView:) name:@"hideProgressActivity" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void) appWillEnterForegroundNotification: (NSNotification*) notification
{
    [self getUserLocation];    
}

#pragma mark Map functions

- (void)updateMapMarkers: (NSNotification *) notification
{    
    //inserting/updating map annotations
    //new annotations are checked against current annotations
    
    if (!newDriverList) {
        newDriverList = [[NSArray alloc]init];
    }    
    newDriverList = [[[GlobalVariables myGlobalVariables] gDriverList] allValues]; 
    
    if (!oldDriverList) {
        oldDriverList = [[NSArray alloc]init];
        [mapView addAnnotations:newDriverList];

    
    } else {
        
        NSMutableArray *tempAddList;
        NSMutableArray *tempRemoveList;
        tempAddList = [NSMutableArray arrayWithArray:newDriverList];
        tempRemoveList = [NSMutableArray arrayWithArray:oldDriverList];

        if (![tempAddList containsObject:oldDriverList]) {
            [tempAddList removeObjectsInArray:oldDriverList];
            [mapView addAnnotations:tempAddList];

        }

        if (![tempRemoveList containsObject:newDriverList]) {
            [tempRemoveList removeObjectsInArray:newDriverList];
            [mapView removeAnnotations:tempRemoveList];
        }
       
    }
    // updating the old driver list
    oldDriverList = newDriverList;
}

- (void)getUserLocation 
{	
    if (!clManager){
        clManager = [[CoreLocationManager alloc]init];
    }
    
    [clManager startLocationManager:nil];
}

- (void)updateUserMarker: (NSNotification *) notification
{
    //updates user marker + orientates screen to user location
    
    if (!userLocationAnnotation) {
        userLocationAnnotation = [[UserLocationAnnotation alloc]init];
    } else {
        [mapView removeAnnotation:userLocationAnnotation];
    }
    CLLocationCoordinate2D coordinate;
    coordinate.latitude =[[[[GlobalVariables myGlobalVariables] gCurrentForm]objectForKey:@"pickup_latitude"]floatValue];
    coordinate.longitude =[[[[GlobalVariables myGlobalVariables] gCurrentForm]objectForKey:@"pickup_longitude"]floatValue];
    
	span.latitudeDelta=0.01;
	span.longitudeDelta=0.01;	 
	region.span=span;
    region.center=coordinate;
    
    [mapView setRegion:region animated:TRUE];
	[mapView regionThatFits:region];
        
    [userLocationAnnotation setCoordinateWithGV];
    [self addAnnotationUserMarker];
    
    [OtherQuery getNearestTimeWithlocation:coordinate completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

        
            // webservice specific
        if (data) {            
            
            NSMutableDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSString* timeString = [dict objectForKey:@"time"];
            NSLog(@"%@ - %@ - getNearest - %@",self.class,NSStringFromSelector(_cmd), timeString);

            
            int timeInt = [timeString intValue];
            if (timeInt != 0)
                [self performSelectorOnMainThread:@selector(setNearestDriverTimeText:) withObject:[dict objectForKey:@"time"] waitUntilDone:YES];
        }
    }];

}

- (void) setNearestDriverTimeText:(NSString*) time
{
    [nextButton setTitle:[NSString stringWithFormat: @"Get a cab in %@ minutes", time] forState:UIControlStateNormal];
}

- (void) addAnnotationUserMarker
{
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    [mapView addAnnotation:userLocationAnnotation];
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
    //set annotation views for user
    if (annotation.title == @"User Location")
    {
    	MKAnnotationView *annView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"userloc"];
        annView.image = [UIImage imageNamed:@"passengerMarker"];
        annView.centerOffset = CGPointMake(0, -20);
        annView.draggable = YES;
        annView.canShowCallout = NO;        
         return annView;
    }else{
    //set annotation views for driver

        MKAnnotationView *annView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"driverloc"];
        annView.image = [UIImage imageNamed:@"driverMarker"];
        annView.canShowCallout = NO;
        	return annView;

    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
}

#pragma mark Downloading Drivers Position
-(void) showActivityView:(NSNotification*) notification
{    
    NSLog(@"%@ - %@",self.class,NSStringFromSelector(_cmd));

    // disable get cab button
    [nextButton setUserInteractionEnabled:NO];
    
    // Spinning thingy code 
    activityContainer = [[ActivityProgressView alloc] initWithFrame:CGRectMake(0, 0, 200, 80) text:@"Connecting..."];
    [self.view addSubview:activityContainer];
}

-(void) hideActivityView:(NSNotification*) notification
{
    // enable get cab button
    [nextButton setUserInteractionEnabled:YES];
    
    // Stop spinning thingy code
    if (activityContainer)
        [activityContainer removeFromSuperview];
}

#pragma mark Other Functions

-(void) updateGeoAddress:(NSNotification*) notification
{
    // change text in search bar to reverse geocoded address
    [self.searchDisplayController.searchBar setPlaceholder:[[[GlobalVariables myGlobalVariables]gCurrentForm]objectForKey:@"pickup_address"]];
}

#pragma mark Search functions
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if ([searchText length] > 2) {
		if (loading) {
			dirty = YES;
		} else {
			[self loadSearchSuggestions];
		}
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	return NO;
}

- (void) loadSearchSuggestions {
	loading = YES;
	NSString* query = self.searchDisplayController.searchBar.text;
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&sensor=true&key=%@&components=country:my", query, apiKey];
    
    urlString =  [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        
        NSMutableArray *sug =[[NSMutableArray alloc]initWithCapacity:5 ];
        NSMutableArray *ref =[[NSMutableArray alloc]initWithCapacity:5];
        
        NSDictionary* tester = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil]; 
        NSArray* testArray = [tester objectForKey:@"predictions"];
        
        for (NSDictionary *result in testArray) {            
            
            NSArray* terms = [result objectForKey:@"terms"];
            NSDictionary *term0 = [terms objectAtIndex:0];
            NSString* resultname = [term0 objectForKey:@"value"]; 
            
            //NSLog([result objectForKey:@"value"]);
            NSLog(@"%@",resultname);
            [sug addObject:resultname];
            [ref addObject:[result objectForKey:@"reference"]];
        }        
        
        self.suggestions = sug;
        self.references = ref;
        
        //[self.searchDisplayController.searchResultsTableView reloadData];
        [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES]; 
        
        loading = NO;
        if (dirty) {
            dirty = NO;
            [self loadSearchSuggestions];
        }
    }];
    
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"suggestMain";	
	UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:cellIdentifier];
    
	if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] ;
		cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0];
	}
    cell.textLabel.text = [suggestions objectAtIndex:indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchDisplayController setActive:NO animated:YES];
        [self.searchDisplayController.searchBar setPlaceholder:[suggestions objectAtIndex:indexPath.row]];
    [mapView removeAnnotations:mapView.annotations];
    NSString* refID = [references objectAtIndex:indexPath.row];    
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&sensor=true&key=%@", refID, apiKey];
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@",urlString);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] ==200) {
            
        NSDictionary* tester = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil]; 
        NSDictionary* result = [tester objectForKey:@"result"];
        NSDictionary* geo = [result objectForKey:@"geometry"];
        NSDictionary* location = [geo objectForKey:@"location"];
     
        CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([[location objectForKey:@"lat"]doubleValue], [[location objectForKey:@"lng"]doubleValue]);    

        span.latitudeDelta=0.007;
        span.longitudeDelta=0.007;	 
        region.span=span;
        region.center=coordinate;
        
        NSLog(@"%@ - %@",self.class,NSStringFromSelector(_cmd));
        
        [[[GlobalVariables myGlobalVariables]gCurrentForm]setObject:[NSString stringWithFormat:@"%f",coordinate.latitude] forKey:@"pickup_latitude"];
        [[[GlobalVariables myGlobalVariables]gCurrentForm]setObject:[NSString stringWithFormat:@"%f",coordinate.longitude] forKey:@"pickup_longitude"];
        [[[GlobalVariables myGlobalVariables]gCurrentForm]setObject:[suggestions objectAtIndex:indexPath.row] forKey:@"pickup_address"];
        
        
        [userLocationAnnotation initWithCoordinate:coordinate];
        [self performSelectorOnMainThread:@selector(addAnnotationUserMarker) withObject:nil waitUntilDone:YES];
        
        //[self performSelectorOnMainThread:@selector(updateMapMarkers:) withObject:nil waitUntilDone:YES]; 
        
        [mapView performSelectorOnMainThread:@selector(addAnnotations:) withObject:[[[GlobalVariables myGlobalVariables]gDriverList]allValues] waitUntilDone:YES];
        }

    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [suggestions count];
}

#pragma mark UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tbc shouldSelectViewController:(UIViewController *)vc {
    UIViewController *tbSelectedController = tbc.selectedViewController;
    
    if ([tbSelectedController isEqual:vc]) {
        return NO;
    }
    
    return YES;
}


   

@end
