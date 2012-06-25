//
//  AppDelegate.h
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

@class MainViewController;
@class Rdio;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    ALAssetsLibrary *_library;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic, readonly) Rdio* rdio;
@property (strong, nonatomic, readonly) NSMutableArray *assetsArray;

+(AppDelegate*)sharedInstance;

@end
