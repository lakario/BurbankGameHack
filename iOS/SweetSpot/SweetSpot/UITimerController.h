//
//  UITimerController.h
//  SweetSpot
//
//  Created by Nathan Taylor on 5/3/14.
//  Copyright (c) 2014 burbankgames. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITimerContoller : UIViewController {
    
    NSTimer *timer;
    IBOutlet UILabel *myCounterLabel;
}

@property (nonatomic, retain) UILabel *myCounterLabel;
-(void)updateCounter:(NSTimer *)theTimer;
-(void)countdownTimer;

@end