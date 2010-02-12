//
//  IGKApplicationDelegate.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController;

@interface IGKApplicationDelegate : NSObject
{
	NSMutableArray *windowControllers;
	
	IGKLaunchController *launchController;
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectContext *backgroundManagedObjectContext;
}

- (BOOL)hasMultipleWindowControllers;

- (IBAction)showWindow:(id)sender;
- (IBAction)newWindow:(id)sender;

- (NSString *)developerDirectory;

// Core Data Nonsense

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *backgroundManagedObjectContext;

- (IBAction)saveAction:sender;

@end
