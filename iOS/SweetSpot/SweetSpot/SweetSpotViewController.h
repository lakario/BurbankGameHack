//
//  SweetSpotViewController.h
//  SweetSpot
//
//  Created by Nathan Taylor on 5/3/14.
//  Copyright (c) 2014 burbankgames. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SweetSpotViewController : UIViewController
{
    NSTimer *timer;
    NSTimer *gameLoop;
    int score;
    NSUUID* selectedBeaconUUID;
    int ticksSinceBeaconChange;
    int ticksSinceRangeChange;
    int switchCountdown;
    int gameTime;
    bool gameOver;
}
@property (weak, nonatomic) IBOutlet UILabel *lblBeaconsFound;
-(void)updateGame;

@end
