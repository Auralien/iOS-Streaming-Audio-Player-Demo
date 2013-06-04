//
//  SMPAppDelegate.h
//  StreamingMusicPlayer
//
//  Created by Maxim Mikheev on 03.06.13.
//  Copyright (c) 2013 Maxim Mikheev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMPViewController;

@interface SMPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SMPViewController *viewController;

@end
