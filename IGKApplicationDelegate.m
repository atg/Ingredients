//
//  IGKApplicationDelegate.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Written in 2010 by Fileability.
//

#import "IGKApplicationDelegate.h"
#import "IGKWindowController.h"
#import "IGKLaunchController.h"
#import <WebKit/WebKit.h>
#import "IGKAnnotationManager.h"

const NSInteger IGKStoreVersion = 2;

@implementation IGKApplicationDelegate

@synthesize windowControllers;
@synthesize preferencesController;
@synthesize fullscreenWindowController;
@synthesize xmlDocumentCache;
@synthesize htmlCache;

- (id)init
{
	if (self = [super init])
	{
		NSString *appSupportPath = [@"~/Library/Application Support/Ingredients/" stringByExpandingTildeInPath];
#ifndef NDEBUG
		if (NSRunAlertPanel(@"Start Over(ish)?", @"Should I clear out the app support folder and preferences?", @"Clear", @"Keep", nil)) {
			NSLog(@"appSupportPath = %@", appSupportPath);
			
			[[NSFileManager defaultManager] removeItemAtPath:appSupportPath error:nil];
			
			NSString *prefsPath = [@"~/Library/Preferences/net.fileability.ingredients" stringByExpandingTildeInPath];			
			NSLog(@"prefsPath = %@", prefsPath);
			[[NSFileManager defaultManager] removeItemAtPath:prefsPath error:nil];
		}
#endif
		
		//Load core data
		[self managedObjectContext];
		
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"IGKShowAnnotations"])
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IGKShowAnnotations"];
		}
		
		launchController = [[IGKLaunchController alloc] init];
		launchController.appController = self;
		
		windowControllers = [[NSMutableArray alloc] init];
		
		BOOL isIndexing = [launchController launch];
		
		docsetCount = 1;
		//If we're not indexing and there's no docsets in sight, show the preferences dialog
		if (!isIndexing)
		{
			NSError *err = nil;
			NSFetchRequest *docsetCountFetch = [[NSFetchRequest alloc] init];
			[docsetCountFetch setEntity:[NSEntityDescription entityForName:@"Docset" inManagedObjectContext:managedObjectContext]];
			docsetCount = [managedObjectContext countForFetchRequest:docsetCountFetch error:&err];
			
			[launchController finishedLoading];
		}
		
		//init history
		history = [[WebHistory alloc] init];
		[history loadFromURL:[NSURL fileURLWithPath:[[self applicationSupportDirectory] stringByAppendingPathComponent:@"history"]] error:nil];
		[WebHistory setOptionalSharedHistory:history];
		
		if (docsetCount > 0)
		{
			[self newWindowIsIndexing:isIndexing];
		}
		else
		{
			preferencesController = [[NSClassFromString(@"IGKPreferencesController") alloc] init];
			[preferencesController setStartIntoDocsets:YES];
			
			[self showPreferences:nil];
		}
		
		// init the annotations...
		[[IGKAnnotationManager sharedAnnotationManager] loadAnnotations];
		
		
		xmlDocumentCache = [[NSCache alloc] init];
		[xmlDocumentCache setCountLimit:12];
		[xmlDocumentCache setEvictsObjectsWithDiscardedContent:YES];
		
		htmlCache = [[NSCache alloc] init];
		[htmlCache setTotalCostLimit:30 * 1024];
		[htmlCache setEvictsObjectsWithDiscardedContent:YES];
	}
	
	return self;
}

- (BOOL)hasMultipleWindowControllers
{
	return YES;
}

- (IBAction)showPreferences:(id)sender
{
	//We load preferences lazily
	if (!preferencesController)
		preferencesController = [[NSClassFromString(@"IGKPreferencesController") alloc] init];
	
	[preferencesController showWindow:sender];
}

- (IBAction)showWindow:(id)sender
{
	if ([self hasMultipleWindowControllers] && ![windowControllers count])
	{
		[self newWindow:sender];
		return;
	}
	
	[[windowControllers lastObject] showWindow:sender];
}

- (IBAction)newWindow:(id)sender
{
	[self newWindowIsIndexing:NO];
}
- (id)newWindowIsIndexing:(BOOL)isIndexing
{
	if (docsetCount == 0)
		return;
	
	if (![self hasMultipleWindowControllers] && [windowControllers count])
	{
		[self showWindow:nil];
		return;
	}
	
	IGKWindowController *windowController = [[IGKWindowController alloc] init];
	windowController.appDelegate = self;
	[windowControllers addObject:windowController];
	
	if (isIndexing)
		windowController.shouldIndex = YES;
	[windowController showWindow:nil];
	
	return windowController;
}

- (void)finalize
{
	dispatch_release(backgroundQueue);
	
	[super finalize];
}

#pragma mark Core Data Nonsense

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Ingredients" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Ingredients"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
	return managedObjectModel;
}

- (BOOL)deleteStoreFromDisk:(NSString *)urlpath
{	
	//Pointless checks because I'm paranoid about deleting things
	
	if (![urlpath length])
		return NO;
	
	BOOL isdir = NO;
	NSError *error = nil;
	
	//Check that the file is not a directory
	if ([[NSFileManager defaultManager] fileExistsAtPath:urlpath isDirectory:&isdir] && isdir == NO)
	{			
		//Check that there's an "Ingredients" component in there somewhere (so we're not going to be deleting ~/ or whatever)
		if ([[urlpath pathComponents] containsObject:@"Ingredients"])
		{
			//Delete the store
			if ([[NSFileManager defaultManager] removeItemAtPath:urlpath error:&error])
			{
				if (!error)
				{
					return YES;
				}
			}
		}
	}
	
	return NO;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    
	//There was an error. The user's store is probably an incorrect version. To fix that we delete the store and start again
	NSString *urlpath = [[url path] stringByStandardizingPath];
	
	BOOL needsReindex = [[NSUserDefaults standardUserDefaults] boolForKey:@"needsReindex"];
	if (needsReindex)
	{
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"needsReindex"];
	}
	
	BOOL isOutOfDate = NO;
	NSInteger storeVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"storeVersion"];
	isOutOfDate = storeVersion < IGKStoreVersion;
	
	if (isOutOfDate)
	{
		[[NSUserDefaults standardUserDefaults] setInteger:IGKStoreVersion forKey:@"storeVersion"];
	}
	
	if (needsReindex || isOutOfDate)
	{
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self deleteStoreFromDisk:urlpath];
	}
	
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error])
	{
		//There was an error. The user's store is probably an incorrect version. To fix that we delete the store and start again
		
		if ([self deleteStoreFromDisk:urlpath])
		{
			//Reread the store
			if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
														 configuration:nil 
																   URL:url 
															   options:nil 
																 error:&error])
			{
				return persistentStoreCoordinator;
			}
		}
		
		/*
		 //Check that the file is not a directory
		 if ([[NSFileManager defaultManager] fileExistsAtPath:urlpath isDirectory:&isdir] && isdir == NO)
		 {			
		 //Check that there's an "Ingredients" component in there somewhere (so we're not going to be deleting ~/ or whatever)
		 if ([[urlpath pathComponents] containsObject:@"Ingredients"])
		 {
		 //Delete the store
		 if ([[NSFileManager defaultManager] removeItemAtPath:urlpath error:&error])
		 {
		 //Reread the store
		 if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
		 configuration:nil 
		 URL:url 
		 options:nil 
		 error:&error])
		 {
		 return persistentStoreCoordinator;
		 }
		 }
		 }
		 }
		 */
		
		//That didn't work. Show an unintelligible error message instead.
		[[NSApplication sharedApplication] presentError:error];;
		persistentStoreCoordinator = nil;
		
		return nil;
    }
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext)
		return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
	
    return managedObjectContext;
}

//A managed object context to use for background operations
- (NSManagedObjectContext *)backgroundManagedObjectContext {
	
    if (backgroundManagedObjectContext)
		return backgroundManagedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (!coordinator)
	{
        return nil;
    }
	
    backgroundManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [backgroundManagedObjectContext setPersistentStoreCoordinator:coordinator];
	[backgroundManagedObjectContext setUndoManager:nil];
	
    return backgroundManagedObjectContext;
}

- (dispatch_queue_t)backgroundQueue
{
	if (backgroundQueue == NULL)
		backgroundQueue = dispatch_queue_create(NULL, NULL);
	
	return backgroundQueue;
}

/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
	// Save history
	NSError *error2 = nil;
	[[WebHistory optionalSharedHistory] saveToURL:[NSURL fileURLWithPath:[[self applicationSupportDirectory] stringByAppendingPathComponent:@"history"]] error:&error2];
	NSLog(@"Error: %@", [error2 localizedDescription]);
	
	// Save annotations
	[[IGKAnnotationManager sharedAnnotationManager] saveAnnotations];
	
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
	return NSTerminateNow;
}

@end