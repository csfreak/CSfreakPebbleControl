//
//  AppDelegate.m
//  CSfreakPebbleControl
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import "AppDelegate.h"
#import "PebbleKit/PebbleKit.h"
#import "ViewController.h"

#import "CZWeatherKit/CZWeatherKit.h"

//#import "ASLocationMonitor/ASLocationMonitor.h"
#import <CoreLocation/CoreLocation.h>

#import "ASBatteryMonitor/ASBatteryMonitor.h"

#define CS_BATTERY_LEVEL_KEY @(0xFFFE)
#define CS_BATTERY_STATUS_KEY @(0xFFFD)
#define CS_STOCK_TICKER_KEY @(0xFFEF)
#define CS_STOCK_VALUE_KEY @(0xFFEE)
#define CS_WEATHER_TEMP_F_KEY @(0xFFDF)
#define CS_WEATHER_TEMP_C_KEY @(0xFFDE)
#define CS_WEATHER_COND_KEY @(0xFFDD)
#define CS_WEATHER_HUMID_KEY @(0xFFDC)
#define CS_WEATHER_WIND_SPEED_KEY @(0xFFDB)
#define CS_WEATHER_WIND_DIR_KEY @(0xFFDA)

#define CS_UPDATE_BATTERY_KEY @(0x0FFF)
#define CS_UPDATE_STOCK_KEY @(0x0FFE)
#define CS_UPDATE_WEATHER_KEY @(0x0FFD)




@interface AppDelegate () <PBPebbleCentralDelegate>
@property (weak, atomic) PBWatch *watch;
@property (weak, atomic) PBPebbleCentral *central;

@property (atomic) CZOpenWeatherMapRequest *OWrequest;
@property (strong) CLLocationManager *locationManager;
@property (strong) CLLocation *location;
@property (strong) CZWeatherCurrentCondition *weather;
@property (strong) NSString *stockValue;

@property (weak) ASBatteryMonitor *batteryMonitor;

@property id appMessageHandle;
@property (strong) ViewController* ViewController;


@end

@implementation AppDelegate
CLLocationDistance TenMiles = 16000;
@synthesize ViewController =  _ViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set the delegate to receive PebbleKit events
    self.central = [PBPebbleCentral defaultCentral];
    NSLog(@"Central Created");
    self.central.delegate = self;
    // Register UUID
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"325fdc12-bf67-48fa-a571-83876880ef88"];
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

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)initPebble {
    
    
    
    [self.watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo ) {
        NSLog(@"Pebble firmware os version: %li", (long)versionInfo.runningFirmwareMetadata.version.os);
        NSLog(@"Pebble firmware major version: %li", (long)versionInfo.runningFirmwareMetadata.version.major);
        NSLog(@"Pebble firmware minor version: %li", (long)versionInfo.runningFirmwareMetadata.version.minor);
        NSLog(@"Pebble firmware suffix version: %@", versionInfo.runningFirmwareMetadata.version.suffix);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Pebble Label");
            //[[ViewController outputLabel].text = [NSString stringWithFormat:@"Connected to %@", [watch name]];
        });
        
    }
                     onTimeout:^(PBWatch *watch) {
                         NSLog(@"Timed out trying to get version info from Pebble.");
                     }];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Adding App Message Handle");
        self.appMessageHandle = [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
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
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        [self updateStock];
        [self updateWeather];
        [self updateBattery];
        
    });
    
}

- (void)deinitPebble {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.watch appMessagesRemoveUpdateHandler:self.appMessageHandle];
    });
}

- (void)processPebbleDictionary:(NSDictionary *)update  {
    NSLog(@"Received message");
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
    if (self.watch) {
        NSLog(@"Update sent to %@:%@", [self.watch name], update);
        
        [self.watch appMessagesPushUpdate:update onSent:nil];
        /*^(PBWatch *watch, NSDictionary *update, NSError *error) {
         if(!error) {
         NSLog(@"Pushed update.");
         } else {
         NSLog(@"Error pushing update: %@", error);
         }
         }];*/
    } else {
        NSLog(@"Abort Send for lack of pebble");
    }
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
            //[ViewController updateOutputLabel: [NSString stringWithFormat:@"Pebble Not Connected"]];
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
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Main Thread Dispatch:  Set Stock Labels");
        [self.ViewController updateStockLabel: [NSString stringWithFormat:@"VSAT Stock Value: %@",self.stockValue]];
        //[self performSelectorOnMainThread:@selector(sendUpdate:) withObject:@{CS_STOCK_TICKER_KEY: @"VSAT",CS_STOCK_VALUE_KEY:self.stockValue} waitUntilDone:NO];
        [self sendUpdate: @{CS_STOCK_TICKER_KEY: @"VSAT",CS_STOCK_VALUE_KEY:self.stockValue}];
        
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
                        NSLog(@"Main Thread Dispatch:  Set Weather Labels");
                        [self.ViewController updateWeatherTempLabel: [NSString stringWithFormat:@"Current Weather Temp: %2.1f%C",self.weather.temperature.f,0x2109 ]];
                        [self.ViewController updateWeatherCondLabel: [NSString stringWithFormat:@"Current Weather Condition: %@",self.weather.summary]];
                        //[self performSelectorOnMainThread:@selector(sendUpdate:) withObject:@{CS_WEATHER_TEMP_F_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.f],CS_WEATHER_TEMP_C_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.c],CS_WEATHER_COND_KEY:self.weather.summary,CS_WEATHER_HUMID_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.humidity]} waitUntilDone:NO];
                        [self sendUpdate: @{CS_WEATHER_TEMP_F_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.f],CS_WEATHER_TEMP_C_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.temperature.c],CS_WEATHER_COND_KEY:self.weather.summary,CS_WEATHER_HUMID_KEY: [NSString stringWithFormat:@"%1.0f",self.weather.humidity]}];
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
            NSLog(@"Main Thread Dispatch:  Set Battery Level Label");
            [self.ViewController updateBatteryLevelLabel: [NSString stringWithFormat:@"Phone Battery Level: %.f%%",self.batteryMonitor.percentage * 100]];
            //[self performSelectorOnMainThread:@selector(sendUpdate:) withObject:@{CS_BATTERY_LEVEL_KEY: [NSNumber numberWithFloat:self.batteryMonitor.percentage*100]} waitUntilDone:NO];
            [self sendUpdate: @{CS_BATTERY_LEVEL_KEY: [NSNumber numberWithInt32:self.batteryMonitor.percentage*10]}];
            NSLog(@"Sent Battery Level: %@", [NSNumber numberWithFloat:self.batteryMonitor.percentage*10]);
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
                state=[NSNumber numberWithInt8:3];
                break;
                
            case UIDeviceBatteryStateCharging:
                log_state = @"Charging";
                state=[NSNumber numberWithInt8:2];
                break;
                
            case UIDeviceBatteryStateUnplugged:
                log_state = @"Unplugged";
                state=[NSNumber numberWithInt8:1];
                break;
                
            default:
                log_state = @"Unknown";
                state=[NSNumber numberWithInt8:0];
                break;
        }
        NSLog(@"State: %@, Sent State: %@",log_state,state);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Main Thread Dispatch:  Set Battery Cond Label");
            [self sendUpdate: @{CS_BATTERY_STATUS_KEY: state}];
            [self.ViewController updateBatteryCondLabel: [NSString stringWithFormat:@"Phone Battery Level: %@",log_state]];
        });
    }
    
}




@end
