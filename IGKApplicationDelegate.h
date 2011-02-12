//
//  IGKApplicationDelegate.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController;
@class WebHistory;
@class IGKWindowController;

@interface IGKApplicationDelegate : NSObject
{
	NSMutableArray *windowControllers;
	
	IGKLaunchController *launchController;
	IGKWindowController *fullscreenWindowController;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectContext *backgroundManagedObjectContext;
	WebHistory *history;
	
	id preferencesController;
	
	dispatch_queue_t backgroundQueue;
	
	NSUInteger docsetCount;
	
	//The NSXMLDocument cache caches parsed NSXMLDocument trees and references them by their location on disk
	NSCache *xmlDocumentCache;
	
	//The HTML cache caches various pieces of parsed html to save the computer from parsing the same thing twice
	NSCache *htmlCache;
	
	BOOL applicationIsIndexing;
}

@property (readonly) NSMutableArray *windowControllers;
@property (readonly) id preferencesController;
@property (assign) IGKWindowController *fullscreenWindowController;

@property (assign) NSCache *xmlDocumentCache;
@property (assign) NSCache *htmlCache;

- (BOOL)hasMultipleWindowControllers;

- (dispatch_queue_t)backgroundQueue;

- (IBAction)showPreferences:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)newWindow:(id)sender;
- (id)newWindowIsIndexing:(BOOL)isIndexing;

- (NSString *)developerDirectory;

- (void)queryString:(NSString *)query;

// Core Data Nonsense

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *backgroundManagedObjectContext;

- (BOOL)deleteStoreFromDisk:(NSString *)urlpath;

- (IBAction)saveAction:sender;
- (IBAction)newWindow:(id)sender;

@end
