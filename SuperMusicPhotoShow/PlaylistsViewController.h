//
//  PlaylistsViewController.h
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlaylistsViewController;

@protocol PlaylistsViewControllerDelegate <NSObject>

- (void)didCancelChoosingPlaylist;
- (void)didChoosePlaylist:(NSDictionary*)playlist;

@end

@interface PlaylistsViewController : UITableViewController

@property (nonatomic, retain) NSDictionary *playlists;
@property (nonatomic, retain) id<PlaylistsViewControllerDelegate> delegate;

@end
