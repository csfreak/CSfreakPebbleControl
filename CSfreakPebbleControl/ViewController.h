//
//  ViewController.h
//  CSfreakPebbleControl
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UILabel *StockLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *WeatherCondLabel;
@property (weak, nonatomic) IBOutlet UILabel *BatteryLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *BatteryCondLabel;

- (void)updateOutputLabel: (NSString*)string;
- (void)updateStockLabel: (NSString*)string;
- (void)updateWeatherTempLabel: (NSString*)string;
- (void)updateWeatherCondLabel: (NSString*)string;
- (void)updateBatteryLevelLabel: (NSString*)string;
- (void)updateBatteryCondLabel: (NSString*)string;


@end

