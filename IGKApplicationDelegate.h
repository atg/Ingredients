//
//  IGKApplicationDelegate.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController, IGKPreferencesController;

@interface IGKApplicationDelegate : NSObject
{
	NSMutableArray *windowControllers;
	
	IGKLaunchController *launchController;
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectContext *backgroundManagedObjectContext;
	
	IGKPreferencesController *preferencesController;
	
	dispatch_queue_t backgroundQueue;
}

- (BOOL)hasMultipleWindowControllers;

- (IBAction)showPreferences:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)newWindow:(id)sender;
- (void)newWindowIsIndexing:(BOOL)isIndexing;

- (NSString *)developerDirectory;

// Core Data Nonsense

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *backgroundManagedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)newWindow:(id)sender;

@end
