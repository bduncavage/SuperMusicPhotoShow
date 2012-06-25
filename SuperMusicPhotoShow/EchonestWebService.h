//
//  EchonestWebService.h
//  SuperMusicPhotoShow
//
//  Created by Brett Duncavage on 6/22/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EchonestWebService : NSObject

+(void)getBeatsForTrackName:(NSString *)trackName artistName:(NSString*)artistName apiKey:(NSString*)apiKey competion:(void (^)(NSArray *))completion;

@end
