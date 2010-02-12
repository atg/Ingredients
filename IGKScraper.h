//
//  IGKScraper.h
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController;

//A scraper takes a .docset and populates a core data database

@interface IGKScraper : NSObject
{
	NSURL *docsetURL;
	NSURL *url;
	NSManagedObjectContext *ctx;
	
	IGKLaunchController *launchController;
	dispatch_queue_t dbQueue;
	
	NSUInteger pathsCount;
	NSUInteger pathsCounter;
	
	NSMutableArray *paths;
	NSManagedObject *scraperDocset;
}

- (id)initWithDocsetURL:(NSURL *)theDocsetURL managedObjectContext:(NSManagedObjectContext *)moc launchController:(IGKLaunchController*)lc dbQueue:(dispatch_queue_t)dbq;
- (NSInteger)findPaths;

@end
