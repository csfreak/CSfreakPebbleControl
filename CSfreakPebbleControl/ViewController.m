//
//  ViewController.m
//  CSfreakPebbleControl
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import "ViewController.h"
#import "PebbleKit/PebbleKit.h"


@interface ViewController () <PBPebbleCentralDelegate>
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UILabel *StockLabel;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@end

@implementation ViewController

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
        self.outputLabel.text = @"Pebble Connected";
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

    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.outputLabel.text = @"Loading.";
    // Set the delegate to receive PebbleKit events
    self.central = [PBPebbleCentral defaultCentral];
    NSLog(@"Central Created");
    self.central.delegate = self;
     self.outputLabel.text = @"Loading..";
    // Register UUID
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"8883df8b-3b31-47d1-89f2-83f59c9f5e5f"];
     self.outputLabel.text = @"Loading...";
    // Begin connection
    [self.central run];
    NSLog(@"Central Run");
     self.outputLabel.text = @"Loading....";
    // Check AppMessage is supported by this watch
    NSError* error = nil;
    self.StockLabel.text = @"VSAT: %@",[NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://download.finance.yahoo.com/d/quotes.csv?s=VSAT&f=l1&e=.csv"] encoding:NSASCIIStringEncoding error:&error];
    NSLog(@"%@",error);

    }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
