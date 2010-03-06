//
//  IGKScraper.h
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController;
@class IGKDocRecordManagedObject;

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

- (void)findPathCount;
- (BOOL)findPaths;
- (void)index;

+ (id)extractManagedObjectFully:(NSManagedObject *)persistobj context:(NSManagedObjectContext *)transientContext;

@end



@interface IGKFullScraper : NSObject
{
	IGKDocRecordManagedObject *persistobj;
	
	IGKDocRecordManagedObject *transientObject;
	NSManagedObjectContext *transientContext;
	
	//We use instance variables in IGKFullScraper as a way of maintaining state without passing arguments
	NSManagedObject *docset;
	NSXMLDocument *doc;
	
	//Some caching of entities
	NSEntityDescription *ObjCMethodEntity;
	NSEntityDescription *ObjCNotificationEntity;
	NSEntityDescription *ParameterEntity;
	NSEntityDescription *SeeAlsoEntity;
	NSEntityDescription *SampleCodeProjectEntity;
}

@property (readonly) NSManagedObject *transientObject;
@property (readonly) NSManagedObjectContext *transientContext;

- (id)initWithManagedObject:(IGKDocRecordManagedObject *)persistentObject;
- (void)start;

- (void)cleanUp;

@end