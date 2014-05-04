//
//  UITimerController.m
//  SweetSpot
//
//  Created by Nathan Taylor on 5/3/14.
//  Copyright (c) 2014 burbankgames. All rights reserved.
//

#import "UITimerController.h"

@interface UITimerContoller ()
@end

@implementation UITimerContoller : UIViewController
@synthesize myCounterLabel;

int hours, minutes, seconds;
int secondsLeft;
int defaultDuration = 90;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self resetTimer:defaultDuration];
    [self countdownTimer];
}

- (void)updateCounter:(NSTimer *)theTimer {
    if(secondsLeft > 0 ){
        secondsLeft -- ;
        hours = secondsLeft / 3600;
        minutes = (secondsLeft % 3600) / 60;
        seconds = (secondsLeft % 3600) % 60;
        myCounterLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
    }
    else{
        [self resetTimer];
    }
}

-(void)countdownTimer{
    
    secondsLeft = hours = minutes = seconds = 0;
//    if([timer isValid])
//    {
//        [timer release];
//    }
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
//    [pool release];
}

-(void)resetTimer:(int)time{
    secondsLeft = time;
}

-(void)resetTimer{
    secondsLeft = defaultDuration;
}
@end
