//
//  AppDelegate.h
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;
@class Rdio;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{

}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic, readonly) Rdio* rdio;

+(AppDelegate*)sharedInstance;

@end
