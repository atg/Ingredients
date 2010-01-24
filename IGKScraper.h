//
//  IGKScraper.h
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//A scraper takes a .docset and populates a core data database

@interface IGKScraper : NSObject
{
	NSURL *url;
	NSManagedObjectContext *ctx;
}

- (id)initWithDocsetURL:(NSURL *)docsetURL managedObjectContext:(NSManagedObjectContext *)moc;
- (void)search;

@end
