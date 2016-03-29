//
//  ViewController.m
//  GeolocationFench
//
//  Created by Omar Faruqe on 2016-03-28.
//  Copyright © 2016 Omar Faruqe. All rights reserved.
//

#import "MapKit/MapKit.h"
#import "ViewController.h"

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *uiSwitch;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *statusCheck;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL mapIsMoving;
@property (strong,nonatomic) MKPointAnnotation *currentAnno;
@property (strong, nonatomic) CLCircularRegion *geoRegion;

@property (strong,nonatomic) MKPointAnnotation *usersAnno;
@property (strong,nonatomic) MKPointAnnotation *businessAnno;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.uiSwitch.enabled = NO;
    self.statusCheck.enabled = NO;
    
    self.statusLabel.text = @"";
    self.eventLabel.text = @"";
    
    self.mapIsMoving = NO;
    
    //Set up the location Manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 3; //meters
    
    //Zoom the map very close
    CLLocationCoordinate2D noLocaiton;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(noLocaiton, 500, 500); // 500 by 500
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    //Create an annotation for the user's location
    [self addCurrentAnnotation];
    
    //Set up a geoRegion object
    [self setUpGeoRegion];
    
    // Check if the device can do geofences
    if([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] == YES){
        //Regardless of authorization, if hardware can support it set up a georeion
        CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
        if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse) || (currentStatus == kCLAuthorizationStatusAuthorizedAlways)){
            self.uiSwitch.enabled = YES;
        }
        else {
            // If not authorized try and get it authorized
            [self.locationManager requestAlwaysAuthorization];
        }
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    else{
        self.statusLabel.text = @"ReoRegions not supported";
    }
}


- (void) locationManager: (CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse) || (currentStatus == kCLAuthorizationStatusAuthorizedAlways)){
        self.uiSwitch.enabled = YES;
    }
}

- (void) mapview:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    self.mapIsMoving = YES;
}
- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    self.mapIsMoving = NO;
}


- (IBAction)switchTapped:(id)sender {
    if(self.uiSwitch.isOn){
        self.mapView.showsUserLocation = YES;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringForRegion:self.geoRegion];
        self.statusCheck.enabled = YES;
    }
    else{
        self.statusCheck.enabled = NO;
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringForRegion:self.geoRegion];
        self.mapView.showsUserLocation = NO;
    }
}

- (void) addCurrentAnnotation{
    self.currentAnno = [[MKPointAnnotation alloc] init];
    self.currentAnno.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);
    self.currentAnno.title = @"My Location";
    
    //User's Initial Location
    self.usersAnno = [[MKPointAnnotation alloc] init];
    self.usersAnno.coordinate = CLLocationCoordinate2DMake(45.493879, -73.636603);
    self.usersAnno.title = @"Users Location";
    
    // Business Location
    self.businessAnno = [[MKPointAnnotation alloc] init];
    self.businessAnno.coordinate = CLLocationCoordinate2DMake(45.495947, -73.634807);
    self.businessAnno.title = @"Business Location";
    
    [self.mapView addAnnotation:self.usersAnno];
    [self.mapView addAnnotation:self.businessAnno];
    
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:self.businessAnno.coordinate radius:150.0];
    [self.mapView addOverlay:circle];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc]initWithCircle:overlay];
    renderer.strokeColor = [UIColor greenColor];
    renderer.fillColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0];
    renderer.lineWidth = 3;
    return renderer;
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    self.currentAnno.coordinate = locations.lastObject.coordinate;
    if(self.mapIsMoving == NO){
        [self centerMap: self.currentAnno];
    }
}

- (void) centerMap:(MKPointAnnotation *)centerPoint{
    [self.mapView setCenterCoordinate:centerPoint.coordinate animated:YES];
}


- (void) setUpGeoRegion{
    self.geoRegion = [[CLCircularRegion alloc]initWithCenter:CLLocationCoordinate2DMake(45.495947,-73.634807) radius:3 identifier:@"MyRegionIdentifier"];
}


- (void) locationManager:(CLLocationManager *)manager didEnterRegion:(nonnull CLRegion *)region {
    UILocalNotification *note = [[UILocalNotification alloc]init];
    note.fireDate = nil;
    note.repeatInterval = 0;
    note.alertTitle = @"GeoFence Alert!";
    note.alertBody = [NSString stringWithFormat:@"You entered the geofence"];
    [[UIApplication sharedApplication]scheduleLocalNotification:note];
    
    self.eventLabel.text = @"Entered";
}

- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    UILocalNotification *note = [[UILocalNotification alloc]init];
    note.fireDate = nil;
    note.repeatInterval = 0;
    note.alertTitle = @"GeoFence Alert!";
    note.alertBody = [NSString stringWithFormat:@"You left the geofence"];
    [[UIApplication sharedApplication]scheduleLocalNotification:note];
    
    self.eventLabel.text = @"Exited";
}

- (void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if(state == CLRegionStateUnknown){
        self.statusLabel.text = @"Uknown";
    }
    else if(state == CLRegionStateInside){
        self.statusLabel.text = @"Inside";
    }
    else if(state == CLRegionStateOutside){
        self.statusLabel.text = @"Outside";
    }
    else{
        self.statusLabel.text = @"Mystery";
    }
    
}

- (IBAction)statusCheckTapped:(id)sender {
    [self.locationManager requestStateForRegion:self.geoRegion];
}



@end
