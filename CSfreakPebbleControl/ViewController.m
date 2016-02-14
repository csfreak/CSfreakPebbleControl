//
//  ViewController.m
//  CSfreakPebbleControl
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    //Set intial Layout
    self.WeatherTempLabel.text = @"Current Weather Temp: Unknown";
    self.WeatherCondLabel.text = @"Current Weather Condition: Unknown";
    self.outputLabel.text = @"Pebble Not Connected";
    self.StockLabel.text = @"VSAT Stock Price: Unknown";
    self.BatteryLevelLabel.text = @"Phone Battery Level: Unknown";
    self.BatteryCondLabel.text = @"Phone Battery State: Unknown";
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateOutputLabel:(NSString*)string{
    self.outputLabel.text = string;
}
- (void)updateStockLabel:(NSString*)string{
    self.StockLabel.text = string;
}
- (void)updateWeatherTempLabel:(NSString*)string{
    self.WeatherTempLabel.text = string;
}
- (void)updateWeatherCondLabel:(NSString*)string{
    self.WeatherCondLabel.text = string;
}
- (void)updateBatteryLevelLabel:(NSString*)string{
    self.BatteryLevelLabel.text = string;
}
- (void)updateBatteryCondLabel:(NSString*)string{
    self.BatteryCondLabel.text = string;
}

@end
