//
//  PlaylistsViewController.m
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import "PlaylistsViewController.h"

@interface PlaylistsViewController (Private)

- (NSString*)playlistKeyForSection:(NSInteger)section;

@end

@implementation PlaylistsViewController
@synthesize playlists = _playlists;
@synthesize delegate = _delegate;

#pragma mark - Private

- (NSString*)playlistKeyForSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"owned";
        case 1:
            return @"collab";
        case 2:
            return @"subscribed";
        default:
            return nil;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:_delegate
                                                                                           action:@selector(didCancelChoosingPlaylist)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_playlists count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_playlists objectForKey:[self playlistKeyForSection:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *lists = [_playlists objectForKey:[self playlistKeyForSection:[indexPath section]]];
    NSDictionary *playlists = [lists objectAtIndex:[indexPath row]];
    
    cell.textLabel.text = [playlists objectForKey:@"name"];
    cell.detailTextLabel.text = [playlists objectForKey:@"owner"];
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Your Playlists", nil);
        case 1:
            return NSLocalizedString(@"Collaborated", nil);
        case 2:
            return NSLocalizedString(@"Subscribed", nil);
        default:
            return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *playlist = [[_playlists objectForKey:[self playlistKeyForSection:[indexPath section]]] objectAtIndex:[indexPath row]];
    [_delegate didChoosePlaylist:playlist];
}

@end
