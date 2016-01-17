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

#define CS_BATTERY_LEVEL_KEY @(0xFFFF)
#define CS_BATTERY_STATUS_KEY @(0xFFFE)
#define CS_STOCK_TICKER_KEY @(0xFFEF)
#define CS_STOCK_VALUE_KEY @(0xFFEF)
#define CS_WEATHER_TEMP_F_KEY @(0xFFDF)
#define CS_WEATHER_TEMP_C_KEY @(0xFFDE)
#define CS_WEATHER_COND_KEY @(0xFFDD)
#define CS_WEATHER_HUMID_KEY @(0xFFDC)
#define CS_WEATHER_WIND_SPEED_KEY @(0xFFDB)
#define CS_WEATHER_WIND_DIR_KEY @(0xFFDA)

#define CS_UPDATE_BATTERY_KEY @(0x0FFF)
#define CS_UPDATE_STOCK_KEY @(0x0FFE)
#define CS_UPDATE_WEATHER_KEY @(0x0FFD)



@interface ViewController () <PBPebbleCentralDelegate>
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UILabel *StockLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherCondLabel;
@property (weak, nonatomic) IBOutlet UILabel *BatteryLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *BatteryCondLabel;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property (nonatomic) CZOpenWeatherMapRequest *OWrequest;
@property (strong) CLLocationManager *locationManager;
@property (strong) CLLocation *location;
@property (strong) CZWeatherCurrentCondition *weather;
@property (strong) NSString *stockValue;

@property (weak) ASBatteryMonitor *batteryMonitor;



@end

@implementation ViewController
CLLocationDistance TenMiles = 16000;
id appMessageHandle;
- (void)initPebble {
    

    
    [self.watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo ) {
        NSLog(@"Pebble firmware os version: %li", (long)versionInfo.runningFirmwareMetadata.version.os);
        NSLog(@"Pebble firmware major version: %li", (long)versionInfo.runningFirmwareMetadata.version.major);
        NSLog(@"Pebble firmware minor version: %li", (long)versionInfo.runningFirmwareMetadata.version.minor);
        NSLog(@"Pebble firmware suffix version: %@", versionInfo.runningFirmwareMetadata.version.suffix);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Pebble Label");
            self.outputLabel.text = [NSString stringWithFormat:@"Connected to %@", [watch name]];
        });
        
    }
                     onTimeout:^(PBWatch *watch) {
                         NSLog(@"Timed out trying to get version info from Pebble.");
                     }];

    appMessageHandle = [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        NSLog(@"Received message");
        if (update) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self processPebbleDictionary:update];
            });

            return YES;
        } else {
            return NO;
        }
    }];
}

- (void)deinitPebble {
    [self.watch appMessagesAddReceiveUpdateHandler:appMessageHandle];
}

- (void)processPebbleDictionary:(NSDictionary *)update  {
    if([update objectForKey:CS_UPDATE_BATTERY_KEY]) {
        [self updateBattery];
    }
    if([update objectForKey:CS_UPDATE_WEATHER_KEY]) {
        [self updateWeather];
    }
    if([update objectForKey:CS_UPDATE_STOCK_KEY]) {
        [self updateStock];
    }

}

- (void)sendUpdate:(NSDictionary *)update {
    [self.watch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if(!error) {
            NSLog(@"Pushed update.");
        } else {
            NSLog(@"Error pushing update: %@", error);
        }
    }];
}


- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
    if (self.watch) {
        return;
    }
    self.watch = watch;
    NSLog(@"Pebble connected: %@", [watch name]);
    [self initPebble];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    if (self.watch == watch) {
        self.watch = nil;
        NSLog(@"Pebble disconnected: %@", [watch name]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Pebble Label");
            self.outputLabel.text = [NSString stringWithFormat:@"Pebble Not Connected"];
        });
        [self deinitPebble];
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
- (void)batteryMonitor:(ASBatteryMonitor *)batteryMonitor didChangeBatteryState:(UIDeviceBatteryState)state {
    NSLog(@"Recieved Battery State: %i",(int)state);
    [self updateBattery];
}

- (void)updateStock {
    NSError* error = nil;
    NSString* ret = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://download.finance.yahoo.com/d/quotes.csv?s=VSAT&f=l1&e=.csv"] encoding:NSASCIIStringEncoding error:&error];
    if (error) {
        NSLog(@"Error fetching stock value: %@", error);
    } else {
        self.stockValue = ret;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sendUpdate: @{CS_STOCK_TICKER_KEY: @"VSAT",CS_STOCK_VALUE_KEY:self.stockValue}];
        });
        
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Main Thread Dispatch:  Set Stock Labels");
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
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [self sendUpdate: @{CS_WEATHER_TEMP_F_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.f],CS_WEATHER_TEMP_C_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.c],CS_WEATHER_COND_KEY:self.weather.summary,CS_WEATHER_HUMID_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.humidity]}];
                    });
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Main Thread Dispatch:  Set Weather Labels");
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sendUpdate: @{CS_BATTERY_LEVEL_KEY: [NSNumber numberWithFloat:self.batteryMonitor.percentage*100]}];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Battery Level Label");
            self.BatteryLevelLabel.text = [NSString stringWithFormat:@"Phone Battery Level: %.f%%",self.batteryMonitor.percentage * 100];
        });
    }
    
    if (!self.batteryMonitor.state) {
        NSLog(@"Error battery state");
    } else {
        NSString* log_state;
        NSNumber* state;
        switch (self.batteryMonitor.state) {
            case UIDeviceBatteryStateFull:
                log_state = @"Full";
                state=[NSNumber numberWithInt:3];
                break;
                
            case UIDeviceBatteryStateCharging:
                log_state = @"Charging";
                state=[NSNumber numberWithInt:2];
                break;
                
            case UIDeviceBatteryStateUnplugged:
                log_state = @"Unplugged";
                state=[NSNumber numberWithInt:1];
                break;
                
            default:
                log_state = @"Unknown";
                state=[NSNumber numberWithInt:0];
                break;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sendUpdate: @{CS_BATTERY_STATUS_KEY: state}];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Battery Cond Label");
            self.BatteryCondLabel.text = [NSString stringWithFormat:@"Phone Battery Level: %@",log_state];
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
    self.BatteryLevelLabel.text = @"Phone Battery Level: Unknown";
    self.BatteryCondLabel.text = @"Phone Battery State: Unknown";
    
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
    if (self.watch) {
        [self initPebble];
    }
    

    
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
