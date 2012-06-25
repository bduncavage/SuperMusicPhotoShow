//
//  EchonestWebService.m
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import "EchonestWebService.h"
#import <Foundation/NSJSONSerialization.h>

@interface EchonestWebService (Private)

+(void)callCompletionOnMainThread:(void (^)(id))completion result:(id)result;

@end

@implementation EchonestWebService

+(void)getBeatsForTrackName:(NSString *)trackName artistName:(NSString*)artistName apiKey:(NSString*)apiKey competion:(void (^)(NSArray *))completion
{
    NSString *endpointFormat = @"http://developer.echonest.com/api/v4/song/search?api_key=%@&format=json&results=1&artist=%@&title=%@&bucket=audio_summary";
    
    NSString *urlWithValues = [NSString stringWithFormat:endpointFormat, apiKey, artistName, trackName];
    NSURL *url = [NSURL URLWithString:[urlWithValues stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSError *error;
        NSArray *beats;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSDictionary *response = [json objectForKey:@"response"];
        if(![[[response objectForKey:@"status"] objectForKey:@"message"] isEqualToString:@"Success"]) {
            [EchonestWebService callCompletionOnMainThread:completion result:beats];
            return;
        }
        
        NSDictionary *song = [[response objectForKey:@"songs"] objectAtIndex:0];
        if(song == nil) {
            [EchonestWebService callCompletionOnMainThread:completion result:beats];
        }
        
        NSDictionary *audioSummary = [song objectForKey:@"audio_summary"];
        if(audioSummary == nil) {
            [EchonestWebService callCompletionOnMainThread:completion result:beats];
            return;
        }
        
        // finally get the audio summary data
        NSData *audioSummaryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[audioSummary objectForKey:@"analysis_url"]]];
        // extract the beats array
        json = [NSJSONSerialization JSONObjectWithData:audioSummaryData options:0 error:&error];
        if(error != nil) {
            [EchonestWebService callCompletionOnMainThread:completion result:beats];
            return;
        }
        
        beats = [json objectForKey:@"segments"];
        [EchonestWebService callCompletionOnMainThread:completion result:beats];
    });
}

+(void)callCompletionOnMainThread:(void (^)(id))completion result:(id)result
{
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(result);
    });
}

@end
