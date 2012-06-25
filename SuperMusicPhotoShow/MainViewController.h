//
//  MainViewController.h
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import "FlipsideViewController.h"
#import "PlaylistsViewController.h"
#import <Rdio/Rdio.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, RdioDelegate, RDAPIRequestDelegate, PlaylistsViewControllerDelegate>
{
    IBOutlet UILabel *loggedInAsLabel;
    IBOutlet UIButton *choosePlaylistButton;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UILabel *currentPlaylistLabel;
    IBOutlet UIView *loggedInView;
    IBOutlet UIView *loggedOutView;
    IBOutlet UIView *beatLoaderView;
    IBOutlet UIView *startSlideshowButton;
    IBOutlet UIView *slideShowView;
    IBOutlet UIImageView *incomingImageView;
    IBOutlet UIImageView *outgointImageView;
    IBOutlet UIButton *stopButton;
    
    NSInteger currentTrackIndex;
    NSDictionary *currentTrack;
    NSMutableArray *cachedImages;
    NSMutableArray *interestingSegments;
    
    NSInteger globalSegementCounter;
    
    uint64_t startedAtTime;
}
@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (strong, nonatomic) NSDictionary *currentPlaylist;

- (IBAction)showInfo:(id)sender;
- (IBAction)showRdioLogin:(id)sender;
- (IBAction)signoutButtonActivated:(id)sender;
- (IBAction)choosePlaylistButtonActivated:(id)sender;
- (IBAction)startSlideshowButtonActivated:(id)sender;

@end
