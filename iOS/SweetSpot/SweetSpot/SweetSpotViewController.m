//
//  SweetSpotViewController.m
//  SweetSpot
//
//  Created by Nathan Taylor on 5/3/14.
//  Copyright (c) 2014 burbankgames. All rights reserved.
//

#import "SweetSpotViewController.h"
#import "ESTBeaconManager.h"
#include <stdlib.h>

@interface SweetSpotViewController () <ESTBeaconManagerDelegate>

@property (nonatomic, strong) ESTBeacon         *beacon;
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;
@property (nonatomic, strong) NSString *selectedBeaconHash;

@property (nonatomic, strong) UISwitch          *enterRegionSwitch;
@property (nonatomic, strong) UISwitch          *exitRegionSwitch;
@property (nonatomic, strong) NSArray           *beaconsArray;
@property (weak, nonatomic) IBOutlet UILabel    *lblScore;
@property (weak, nonatomic) IBOutlet UILabel    *lblHint;
@property (weak, nonatomic) IBOutlet UILabel    *lblSwitchCountdown;
@property (weak, nonatomic) IBOutlet UILabel *lblGameTimer;

@end

@implementation SweetSpotViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.lblSwitchCountdown setHidden:true];
    switchCountdown = -1;
    
	// Do any additional setup after loading the view, typically from a nib.
    
    /*
     * BeaconManager setup.
     */
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    /*
     * Creates sample region object (you can additionaly pass major / minor values).
     *
     * We specify it using only the ESTIMOTE_PROXIMITY_UUID because we want to discover all
     * hardware beacons with Estimote's proximty UUID.
     */
    self.beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                      identifier:@"EstimoteSampleRegion"];
    
    /*
     * Starts looking for Estimote beacons.
     * All callbacks will be delivered to beaconManager delegate.
     */
    [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];

    gameLoop = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(updateGame) userInfo:nil repeats:YES];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateClocks) userInfo:nil repeats:YES];
}


- (void)updateClocks {
    int switchInterval = 5;
    
    if (ticksSinceBeaconChange++ > switchInterval) {
        ticksSinceBeaconChange = 0;
        switchCountdown = 4; // +1 to account for bad coding
    }
    
    [self updateSwitchCountDown];
    [self updateGameTimer];
}

- (void)updateGame {
    int stepSize = 1;
    int modifier = 0;
   
    float distance = round(100 * [self.beacon.distance floatValue]) / 100;
    
    if (self.beacon == nil) {
        self.lblHint.text = @"Unknown - You're too far away!";
    }
    else {
        if (distance <= 3) {
            modifier = stepSize;
            self.lblScore.textColor = [UIColor colorWithRed:52/255.0f green:225/255.0f blue:69/255.0f alpha:1.0f];
        }
        else if (distance > 3 && distance <= 5) {
            modifier = 0;
            self.lblScore.textColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1.0f];
        }
        else { // > 7
            modifier = -1 * stepSize;
            self.lblScore.textColor = [UIColor colorWithRed:255/255.0f green:15/255.0f blue:15/255.0f alpha:1.0f];
        }
        
        self.lblHint.text = [NSString stringWithFormat:@"%0.2f meters - (%@)", distance, [self getBeaconHash:self.beacon]];
    }
    
    score += modifier;
    self.lblScore.text = [self toString:(score)];
}

- (ESTBeacon*)getRandomBeacon {
    if (self.beaconsArray.count == 0) {
        [self handleNoBeacons];
        return nil;
    }
    
    int newIndex = 0;
    BOOL indexSelected = NO;
    
    if (selectedBeaconUUID != nil) {
        int count = 0;
        do {
            newIndex = [self getRandom:(self.beaconsArray.count)];
            count++;
        }
        while ([self.selectedBeaconHash isEqualToString:[self getBeaconHash: ((ESTBeacon *)self.beaconsArray[newIndex])]]);
        
        indexSelected = YES;
    }
    
    if (!indexSelected) {
        newIndex = [self getRandom:(self.beaconsArray.count - 1)];
    }
    
    return self.beaconsArray[newIndex];
}

- (BOOL)compareBeacons:(ESTBeacon *)beacon1 beacon2:(ESTBeacon *)beacon2 {
    return beacon1.proximityUUID == beacon2.proximityUUID
            && beacon1.major == beacon2.major
            && beacon1.minor == beacon2.minor;
}

- (void)handleNoBeacons {
    // blah
}

- (NSString *)getBeaconHash:(ESTBeacon *)beacon {
    return [NSString stringWithFormat:@"%@.%@.%@", beacon.proximityUUID.UUIDString,  beacon.major, beacon.minor];
}

- (void)updateSwitchCountDown {
    if (switchCountdown > 0) {
        switchCountdown--;
        [self.lblSwitchCountdown setHidden:false];
    }
    else {
        if (switchCountdown == -1) {
            [self.lblSwitchCountdown setHidden:true];
        }
        else {
            [self.lblSwitchCountdown setHidden:false];
            self.lblSwitchCountdown.text = @"SWITCH!";
            switchCountdown--;
            
            // switch beacon
            [self setSelectedBeacon:[self getRandomBeacon]];
        }
    }
    
    if (switchCountdown != -1) {
        self.lblSwitchCountdown.text = [NSString stringWithFormat:@"0:0%d", switchCountdown];
    }
}

- (void)updateGameTimer {
    int duration = 180;
    int remaining = duration - ++gameTime;

    self.lblGameTimer.text = [NSString stringWithFormat:@"%02d:%02d", (remaining / 60)%60, remaining%60];
}

- (void)setSelectedBeacon:(ESTBeacon*)beacon {
    selectedBeaconUUID = beacon != nil ? beacon.proximityUUID : nil;
    self.selectedBeaconHash = beacon != nil ? [self getBeaconHash:beacon] : nil;
    self.beacon = beacon;
}

- (void)pickABeacon {
    if (self.beaconsArray.count == 0) {
        self.beacon = nil;
        selectedBeaconUUID = nil;
        return;
    }
    
    int index;
    ESTBeacon *beacon = nil;
    
    if (self.beacon == nil) {
        index = [self getRandom:(self.beaconsArray.count)];
        
        if (index > -1) {
            beacon = self.beaconsArray[index];
        }
    }
    else {
        index = [self findBeaconIndex:self.selectedBeaconHash];
        if (index > -1) {
            beacon = self.beaconsArray[index];
        }
    }
    
    [self setSelectedBeacon:beacon];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)getRandom:(int)max {
    return arc4random_uniform(max);
}

#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = @"Enter region notification";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = @"Exit region notification";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    self.lblBeaconsFound.text = [NSString stringWithFormat:@"%lu", (unsigned long)beacons.count];
    
    self.beaconsArray = beacons;
    
    [self pickABeacon];
}

#pragma mark -


- (void)switchValueChanged
{
    [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
    
    self.beaconRegion.notifyOnEntry = self.enterRegionSwitch.isOn;
    self.beaconRegion.notifyOnExit = self.exitRegionSwitch.isOn;
    
    [self.beaconManager startMonitoringForRegion:self.beaconRegion];
}

- (NSString*)toString:(int)number {
    return [NSString stringWithFormat:@"%d", number];
}

- (int)findBeaconIndex:(NSString *)beaconHash {
    if (beaconHash != nil) {
        for (int i = 0; i < self.beaconsArray.count; i++) {
            ESTBeacon *current = self.beaconsArray[i];
            if ([[self getBeaconHash:current] isEqualToString: beaconHash]) {
                return i;
            }
        }
    }
    return -1;
}

@end
