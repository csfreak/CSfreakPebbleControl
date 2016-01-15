//
//  ViewController.m
//  CSfreakPebbleControl
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import "ViewController.h"
#import "PebbleKit/PebbleKit.h"

#import "CZWeatherKit/CZWeatherKit.h"

//#import "ASLocationMonitor/ASLocationMonitor.h"
#import <CoreLocation/CoreLocation.h>

#import "ASBatteryMonitor/ASBatteryMonitor.h"


@interface ViewController () <PBPebbleCentralDelegate>
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UILabel *StockLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherCondLabel;
@property (weak, nonatomic) IBOutlet UILabel *BatteryLabel;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property (nonatomic) CZOpenWeatherMapRequest *OWrequest;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (weak, nonatomic) CZWeatherCurrentCondition *weather;
@property (strong) NSString *stockValue;

@property (weak, nonatomic) ASBatteryMonitor *batteryMonitor;

@end

@implementation ViewController
CLLocationDistance TenMiles = 16000;

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
    if (self.watch) {
        return;
    }
    self.watch = watch;
    NSLog(@"Pebble connected: %@", [watch name]);
    
    [self.watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo ) {
        NSLog(@"Pebble firmware os version: %li", (long)versionInfo.runningFirmwareMetadata.version.os);
        NSLog(@"Pebble firmware major version: %li", (long)versionInfo.runningFirmwareMetadata.version.major);
        NSLog(@"Pebble firmware minor version: %li", (long)versionInfo.runningFirmwareMetadata.version.minor);
        NSLog(@"Pebble firmware suffix version: %@", versionInfo.runningFirmwareMetadata.version.suffix);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.outputLabel.text = [NSString stringWithFormat:@"Connected to %@", [watch name]];
        });

    }
                     onTimeout:^(PBWatch *watch) {
                         NSLog(@"Timed out trying to get version info from Pebble.");
                     }];

}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    if (self.watch == watch) {
        self.watch = nil;
        NSLog(@"Pebble disconnected: %@", [watch name]);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.outputLabel.text = [NSString stringWithFormat:@"Pebble Not Connected"];
        });
    }
}

/*- (void)locationMonitor:(ASLocationMonitor *)locationMonitor didEnterNeighborhood:(CLLocation *)location{
    self.location = location;
    NSLog(@"Updated Location");
    [self updateWeather];
}*/

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.location = [locations lastObject];
    NSLog(@"Recived Location %@",self.location.description);
    [self updateWeather];
}

- (void)batteryMonitor:(ASBatteryMonitor *)batteryMonitor didChangeBatteryLevel:(CGFloat)level {
    NSLog(@"Recieved Battery Level: %f",level);
    [self updateBattery];
}

- (void)updateStock {
    NSError* error = nil;
    NSString* ret = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://download.finance.yahoo.com/d/quotes.csv?s=VSAT&f=l1&e=.csv"] encoding:NSASCIIStringEncoding error:&error];
    if (error) {
        NSLog(@"Error fetching stock value: %@", error);
    } else {
        self.stockValue = ret;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.StockLabel.text = [NSString stringWithFormat:@"VSAT Stock Value: %@",self.stockValue];
    });
}

- (void)updateWeather {
    if (!self.location) {
        NSLog(@"Waiting for Location");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:5];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateWeather];
            });
        });
    } else {
        NSLog(@"Using Location %@ for weather request",self.location.description);
        self.OWrequest.location = [CZWeatherLocation locationFromLocation:self.location];
        [self.OWrequest sendWithCompletion: ^(CZWeatherData *data, NSError *error) {
            if (error) {
                NSLog(@"Error fetching weather: %@", error);
            } else {
                NSLog(@"Weather fetched Successfully");
                if (!data) {
                    NSLog(@"Weather Request was empty");
                } else if (!data.current) {
                    NSLog(@"Weather Request has no current data");
                } else {
                    self.weather = data.current;
                    NSLog(@"Current Weather Data TempF:%f TempC: %f Condition: %@ Humidity: %f WindSpeed: %f WindDirection: %f", self.weather.temperature.f, self.weather.temperature.c, self.weather.summary, self.weather.humidity, self.weather.windSpeed.mph, self.weather.windDirection);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.WeatherTempLabel.text = [NSString stringWithFormat:@"Current Weather Temp: %2.1f%C",self.weather.temperature.f,0x2109 ];
                        self.WeatherCondLabel.text = [NSString stringWithFormat:@"Current Weather Condition: %@",self.weather.summary];
                    });
                }
            }
        }];
    }
}

- (void)updateBattery {
    if (!self.batteryMonitor.percentage) {
        NSLog(@"Error battery level");
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.BatteryLabel.text = [NSString stringWithFormat:@"Phone Battery Level: %.f%%",self.batteryMonitor.percentage * 100];
        });
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //Set intial Layout
    self.WeatherTempLabel.text = @"Current Weather Temp: Unknown";
    self.WeatherCondLabel.text = @"Current Weather Condition: Unknown";
    self.outputLabel.text = @"Pebble Not Connected";
    self.StockLabel.text = @"VSAT Stock Price: Unknown";
    self.BatteryLabel.text = @"Phone Battery Level: Unknown";
    
    // Set the delegate to receive PebbleKit events
    self.central = [PBPebbleCentral defaultCentral];
    NSLog(@"Central Created");
    self.central.delegate = self;
    // Register UUID
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"8883df8b-3b31-47d1-89f2-83f59c9f5e5f"];
    // Begin connection
    [self.central run];
    NSLog(@"Central Run");
    // Check AppMessage is supported by this watch;
    
    

    
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    self.locationManager.distanceFilter = TenMiles;
    self.locationManager.delegate = self;
    
    //Check LocationAuth Status
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Requesting Location Access");
        [self.locationManager requestAlwaysAuthorization];
    }

    [self.locationManager startUpdatingLocation];
    
    
    self.OWrequest = [CZOpenWeatherMapRequest newCurrentRequest];
    self.OWrequest.key = @"81d7cd5bbf216ebdbff899b3019c69c7";
    
    self.batteryMonitor = [ASBatteryMonitor sharedInstance];
    self.batteryMonitor.delegate = self;
    [self.batteryMonitor startMonitoring];
    
    //Start Background Updates
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        [self updateStock];
        [self updateWeather];
        [self updateBattery];
        
    });

   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
