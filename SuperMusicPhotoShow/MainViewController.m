//
//  MainViewController.m
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "PlaylistsViewController.h"
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import "EchonestWebService.h"
#include <mach/mach_time.h>

@interface MainViewController (Private)

- (void)updateView;
- (void)analyzeSegments:(NSArray*)segments;
- (void)startShow;

@end

@implementation MainViewController
@synthesize currentPlaylist = _currentPlaylist;
@synthesize flipsidePopoverController = _flipsidePopoverController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[AppDelegate sharedInstance].rdio.player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];
    [[AppDelegate sharedInstance].rdio.player addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [AppDelegate sharedInstance].rdio.delegate = self;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:RDIO_ACCESS_TOKEN_PREF];
    if(accessToken != nil) {
        [[AppDelegate sharedInstance].rdio authorizeUsingAccessToken:accessToken fromController:self];
    }
    if([[NSUserDefaults standardUserDefaults] dictionaryForKey:CURRENT_PLAYLIST_PREF] != nil) {
        self.currentPlaylist = [[NSUserDefaults standardUserDefaults] dictionaryForKey:CURRENT_PLAYLIST_PREF];
    }
    
    [self updateView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)updateView
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults stringForKey:RDIO_ACCESS_TOKEN_PREF] != nil) {
        // setup view for logged in user
        NSDictionary *user = [defaults dictionaryForKey:RDIO_USER_INFO_PREF];
        NSString *format = NSLocalizedString(@"Signed in as %@ %@", nil);
        loggedInAsLabel.text = [NSString stringWithFormat:format, [user objectForKey:@"firstName"], [user objectForKey:@"lastName"]];
        choosePlaylistButton.alpha = 1;
        loggedInView.hidden = NO;
        loggedOutView.hidden = YES;
        if(_currentPlaylist != nil) {
            currentPlaylistLabel.text = [_currentPlaylist objectForKey:@"name"];
        }
    } else {
        loggedOutView.hidden = NO;
        loggedInView.hidden = YES;
    }
}

#pragma mark - Button handlers

- (void)showRdioLogin:(id)sender
{
    [[AppDelegate sharedInstance].rdio authorizeFromController:self];
}

- (void)signoutButtonActivated:(id)sender
{
    [[AppDelegate sharedInstance].rdio logout];
    
}

- (void)choosePlaylistButtonActivated:(id)sender
{
    Rdio *rdio = [AppDelegate sharedInstance].rdio;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setObject:[rdio.user objectForKey:@"key"] forKey:@"user"];
    [params setObject:@"tracks" forKey:@"extras"];
    
    [UIView animateWithDuration:0.3 animations:^{
        choosePlaylistButton.alpha = 0;
    }completion:^(BOOL finished) {
        [spinner startAnimating];
        [rdio callAPIMethod:@"getPlaylists" withParameters:params delegate:self];
    }];
}

- (void)startSlideshowButtonActivated:(id)sender
{
    currentTrackIndex = 0;
    Rdio *rdio = [AppDelegate sharedInstance].rdio;
    [rdio.player playSource:[currentTrack objectForKey:@"key"]];
    [UIView animateWithDuration:0.3 animations:^{
        slideShowView.alpha = 1;
    }];
}

#pragma mark - Playlist Delegate

- (void)didChoosePlaylist:(NSDictionary *)playlist
{
    currentTrackIndex = 0;
    
    self.currentPlaylist = playlist;
    [[NSUserDefaults standardUserDefaults] setObject:playlist forKey:CURRENT_PLAYLIST_PREF];
    [self updateView];
    [self dismissModalViewControllerAnimated:YES];
    
    NSArray *tracks = [playlist objectForKey:@"tracks"];
    currentTrack = [tracks objectAtIndex:0];
    NSDictionary *secretInfo = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"secret" ofType:@"plist"]];
    NSString *echonestKey = [secretInfo objectForKey:@"Echonest.Key"];
    
    UIActivityIndicatorView *aiv = (UIActivityIndicatorView*)[beatLoaderView viewWithTag:1234];
    [UIView animateWithDuration:0.3 animations:^{
        beatLoaderView.alpha = 1;
        startSlideshowButton.alpha = 0;
        [aiv startAnimating];
    }];
    
    [EchonestWebService getBeatsForTrackName:[currentTrack objectForKey:@"name"] artistName:[currentTrack objectForKey:@"artist"] apiKey:echonestKey competion:^(NSArray* beats) {
        // analyze the segment data before the song starts
        // this way we can pre-load images from disk, and schedule all
        // of our showNext calls, which should keep us from lagging.
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self analyzeSegments:beats];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    beatLoaderView.alpha = 0;
                    startSlideshowButton.alpha = 1;
                }];
            });
        });
        
        
    }];
}

- (void)analyzeSegments:(NSArray*)segments
{
    cachedImages = [[NSMutableArray alloc] init];
    interestingSegments = [[NSMutableArray alloc] init];
    
    NSArray *assets = [AppDelegate sharedInstance].assetsArray;
    
    int counter = 0;
    int index = 0;
    for (NSDictionary *segment in segments) {
        NSLog(@"analyzing segment %d of %d", index, [segments count]);
        index++;
        float loudness_max = [[segment objectForKey:@"loudness_max"] floatValue];
        float loudness_start = [[segment objectForKey:@"loudness_start"] floatValue];
        
        if(fabs(loudness_start) - fabs(loudness_max) > 5) {
            if(counter < [assets count] && counter < 50) {
                ALAsset *asset = [[AppDelegate sharedInstance].assetsArray objectAtIndex:counter];
                UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
                [cachedImages addObject:image];
            }
            [interestingSegments addObject:segment];
            counter++;
        }
    }
    NSLog(@"Found %d interesting segments!", [interestingSegments count]);
    NSLog(@"Cached %d images", [cachedImages count]);
}

- (void)updateImage:(UIImage*)foo
{
    NSLog(@"Updating image");
    UIImage *image;
    if(globalSegementCounter > [cachedImages count] - 1) {
        globalSegementCounter = 0;
    }
    image = [cachedImages objectAtIndex:globalSegementCounter];
    [incomingImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
    globalSegementCounter++;
}

- (void)startShow
{
    globalSegementCounter = 0;
    int counter = 0;
    for (NSDictionary *segment in interestingSegments) {
        float start = [[segment objectForKey:@"start"] floatValue];
        float loudness_max_time = [[segment objectForKey:@"loudness_max_time"] floatValue];

        if(counter > [cachedImages count] - 1) {
            counter = 0;
        }
        [self performSelector:@selector(updateImage:) withObject:nil afterDelay:start + loudness_max_time + 0.7];
    }
}

- (void)didCancelChoosingPlaylist
{
    [self updateView];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - RDAPIDelegate

- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data
{
    [spinner stopAnimating];
    
    PlaylistsViewController *controller = [[PlaylistsViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.playlists = data;
    controller.delegate = self;
    controller.title = NSLocalizedString(@"Choose a Playlist", nil);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentModalViewController:nav animated:YES];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError *)error
{
    [spinner stopAnimating];
}

#pragma mark - Rdio Delegate

- (void)rdioDidLogout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:RDIO_USER_INFO_PREF];
    [defaults removeObjectForKey:RDIO_ACCESS_TOKEN_PREF];
    [defaults synchronize];
    [self updateView];
}

- (void)rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:user forKey:RDIO_USER_INFO_PREF];
    [defaults setObject:accessToken forKey:RDIO_ACCESS_TOKEN_PREF];
    [defaults synchronize];
    [self updateView];
}

- (void)rdioAuthorizationCancelled
{
    
}

- (void)rdioAuthorizationFailed:(NSString *)error
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                 message:error
                                                delegate:nil
                                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    Rdio *rdio = [AppDelegate sharedInstance].rdio;
    if([keyPath isEqualToString:@"state"]) {
        if(rdio.player.state == RDPlayerStatePlaying) {
            startedAtTime = mach_absolute_time();
            [self startShow];
        }
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    }
}

- (IBAction)showInfo:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:controller animated:YES];
    } else {
        if (!self.flipsidePopoverController) {
            FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
            controller.delegate = self;
            
            self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        }
        if ([self.flipsidePopoverController isPopoverVisible]) {
            [self.flipsidePopoverController dismissPopoverAnimated:YES];
        } else {
            [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

@end
