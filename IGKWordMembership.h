//
//  IGKWordMembership.h
//  Ingredients
//
//  Created by Alex Gordon on 02/05/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//This singleton class keeps an NSHashTable which is used to autolink words in HTML

@interface IGKWordMembership : NSObject {
	NSHashTable *words;
}

+ (IGKWordMembership *)sharedManager;
+ (IGKWordMembership *)sharedManagerWithCapacity:(NSUInteger)capacity;

- (void)addWord:(NSString *)word;
- (NSString *)addHyperlinksToPassage:(NSString *)passage;

@end
