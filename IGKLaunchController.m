//
//  IGKLaunchController.m
//  Ingredients
//
//  Created by Alex Gordon on 10/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKLaunchController.h"
#import "IGKScraper.h"
#import "IGKApplicationDelegate.h"
#import "IGKWordMembership.h"
#import "FUCoreDataStore.h"

@interface IGKLaunchController ()

- (void)addDocsetsInPath:(NSString *)docsets toArray:(NSMutableArray *)docsetPaths set:(NSMutableSet *)docsetsSet developerDirectory:(NSString *)devDir;
- (void)stopIndexing;
- (void)finishedLoading;

@end


@implementation IGKLaunchController

@synthesize appController;

- (NSString *)checkForOrSetDeveloperDirectory
{
	//Check /Developer exists
	BOOL rootDevExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/Developer"];
	if (rootDevExists)
		return @"/Developer";
	
	//Otherwise, ask the user to point us to their developer directory
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Choose developer directory"];
	[openPanel setMessage:@"Please choose a developer directory."];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	
	NSInteger result = [openPanel runModal];
	
	if (result != NSFileHandlingPanelOKButton)
	{
		//If they clicked cancel, make do with what we have (if anything)
		return nil;
	}
	
	NSString *path = [[openPanel URL] path];
		
	//Sanity check path. If it really is a Developer directory, it should have a Library/version.plist
	NSString *versionPlistPath = [path stringByAppendingPathComponent:@"Library/version.plist"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:versionPlistPath];
	if (!exists)
	{
		return nil;
	}
		
	//Seems legit
	return path;
}

- (void)applyDeveloperDirectory:(NSString *)devPath
{
	[[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] addDeveloperDirectoryPath:devPath];
}
- (NSArray *)developerDirectoryDescriptionsFromDefaults
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"developerDirectories"];
}

- (void)saveDocsetPrefs
{
	[[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] saveChanges];
	[[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] reloadTableViews];
}

- (BOOL)launch
{	
	NSMutableSet *docsetPathsSet = [[NSMutableSet alloc] init];
	NSMutableArray *docsetPaths = [[NSMutableArray alloc] init];
	
	//Alloc/Init a shared instance if needed
	[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController];
	
	if ([[self developerDirectoryDescriptionsFromDefaults] count] == 0)
	{
		//First we have to make sure we have a developer directory
		NSString *devdir = [self checkForOrSetDeveloperDirectory];
		
		if (!devdir)
			return NO;
		
		//Save the new dev directory into preferences
		[self applyDeveloperDirectory:devdir];
	}
	
	for (NSString *sharedPath in NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES))
	{
		NSString *docsetSharedPath = [sharedPath stringByAppendingPathComponent:@"Developer/Shared/Documentation/DocSets"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:docsetSharedPath])
		{
			[self addDocsetsInPath:docsetSharedPath
						   toArray:docsetPaths
						       set:docsetPathsSet
				developerDirectory:@"Shared"];
		}
        
        docsetSharedPath = [sharedPath stringByAppendingPathComponent:@"Developer/Documentation/DocSets"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:docsetSharedPath])
		{
			[self addDocsetsInPath:docsetSharedPath
						   toArray:docsetPaths
						       set:docsetPathsSet
				developerDirectory:@"Shared"];
		}
	}
	
	
	for (NSDictionary *description in [self developerDirectoryDescriptionsFromDefaults])
	{ 
		NSString *devdir = [description valueForKey:@"path"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:devdir])
			continue;
		
		//Sanity check path. If it really is a Developer directory, it should have a Library/version.plist
		NSString *versionPlistPath = [devdir stringByAppendingPathComponent:@"Library/version.plist"];
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:versionPlistPath];
		if (!exists)
			continue;
		
		
		
		//Add the default documentation
		[self addDocsetsInPath:[devdir stringByAppendingPathComponent:@"/Documentation/DocSets/"]
					   toArray:docsetPaths
						   set:docsetPathsSet
			developerDirectory:devdir];
		
		NSString *platformsPath = [devdir stringByAppendingPathComponent:@"/Platforms/"];
		NSError *error = nil;
		NSArray *platforms = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:platformsPath error:&error];
		if (!error)
		{
			for (NSString *platform in platforms)
			{
				NSString *platformPath = [platformsPath stringByAppendingPathComponent:platform];
				NSString *platformDocsetsPath = [platformPath stringByAppendingPathComponent:@"/Developer/Documentation/DocSets"];
				
				[self addDocsetsInPath:platformDocsetsPath
							   toArray:docsetPaths
								   set:docsetPathsSet
					developerDirectory:devdir];
			}
		}
	}
	
	/*
	[self addDocsetsInPath:@"/Library/Developer/Shared/Documentation/DocSets/"
				   toArray:docsetPaths
					   set:docsetPathsSet
		developerDirectory:@"Other"];
	*/
	
	dbQueue = dispatch_get_main_queue();
	
	totalPathsCount = 0;
	
	scrapers = [[NSMutableArray alloc] init];
	
	
	BOOL areValidScrapers = NO;
	for (NSDictionary *container in docsetPaths)
	{
		NSString *devDir = [container valueForKey:@"developerDirectory"];
		
		for (NSString *docsetPath in [container valueForKey:@"docsetPaths"])
		{
			IGKScraper *scraper = [[IGKScraper alloc] initWithDocsetURL:[NSURL fileURLWithPath:docsetPath]
												   managedObjectContext:[appController backgroundManagedObjectContext]
													   launchController:self
																dbQueue:dbQueue
													 developerDirectory:devDir];
			if ([scraper findPaths])
			{
				areValidScrapers = YES;
				pathReportsExpected++;
				[scrapers addObject:scraper];
			}
		}
	}
	
	//If there's nothing to scrape
	if (areValidScrapers == NO || ![scrapers count])
	{
		[self saveDocsetPrefs];
		return NO;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"IGKWillIndexedPaths" object:self];
	
	for (IGKScraper *scraper in scrapers)
	{
		[scraper findPathCount];
	}
	
	[self saveDocsetPrefs];
	return YES;
}

- (void)reportPathCount:(NSUInteger)pathCount
{
	pathReportsReceived += 1;
	totalPathsCount += pathCount;
	
	NSLog(@"Getting path report: %d / %d", pathCount, totalPathsCount);
	
	//If we're still expecting paths, return for now
	if (pathReportsReceived < pathReportsExpected)
		return;
	
	if (totalPathsCount == 0)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[self stopIndexing];
		});
		
		return;
	}
	
	//Otherwise send the path count
	NSLog(@"## Total number of paths: %d", totalPathsCount);
	for (IGKScraper *scraper in scrapers)
	{
		[scraper index];
	}
}

//This will be called from the main thread
- (void)reportPath
{
	pathsCounter++;
	
	if (pathsCounter >= totalPathsCount)
	{
		NSLog(@"Saving %@", [appController backgroundManagedObjectContext]);
		
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"IGKWillSaveIndex" object:self];
		
		[self performSelector:@selector(saveDatabaseAndStopIndexing) withObject:nil afterDelay:1.0];
	}
	else
	{
		//A new path
		
		//There's around 200 pixels in the progress bar. We only want to send a notification for each one
		if ((pathsCounter % ((totalPathsCount / 100) ?: 1)) == 0)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"IGKHasIndexedNewPaths" object:self];
		}
	}
}
- (void)saveDatabaseAndStopIndexing
{
	//Save our changes
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		
		[[appController backgroundManagedObjectContext] save:nil];
		[[appController backgroundManagedObjectContext] reset];
		
		[self stopIndexing];
	});
}
- (void)stopIndexing
{
	//Save our changes
	[self finishedLoading];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		//All paths have been reported
		[[NSNotificationCenter defaultCenter] postNotificationName:@"IGKHasIndexedAllPaths" object:self];
        
        [self showFoundNoPathsError];
    });
}
- (void)showFoundNoPathsError
{
    /*
    NSEntityDescription *docRecordEntity = [NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:[appController managedObjectContext]];
    
    NSFetchRequest *fetchEverything = [[NSFetchRequest alloc] init];
    [fetchEverything setEntity:docRecordEntity];
    [fetchEverything setFetchLimit:20];
    */
    
    NSManagedObjectContext *ctx = [appController managedObjectContext];
	dispatch_queue_t queue = [appController backgroundQueue];
	
	if (!queue)
		return;
	/*
	dispatch_sync(queue, ^{
		
		//Oh god, Core Data was *NOT* meant to be used like this
		NSEntityDescription *docRecordEntity = [NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:ctx];
		NSPropertyDescription *nameProperty = [[docRecordEntity propertiesByName] valueForKey:@"name"];
		
		NSFetchRequest *fetchEverything = [[NSFetchRequest alloc] init];
		[fetchEverything setEntity:docRecordEntity];
		[fetchEverything setResultType:NSDictionaryResultType];
		[fetchEverything setReturnsDistinctResults:YES];
		[fetchEverything setPropertiesToFetch:[NSArray arrayWithObject:nameProperty]];
		
		//NSArray *objects = [ctx executeFetchRequest:fetchEverything error:nil];
		
		//NSLog(@"All names: %d", [objects count]);
		
        NSUInteger c = [ctx countForFetchRequest:fetchEverything error:nil];
        
        if (c < 10)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Ingredients could not find any documentation to index."];
            [alert setInformativeText:@"This is usually because Xcode has not downloaded documentation. Try going to Xcode's Documentation preferences and making sure the docsets you want have been downloaded.\n\nThis can also happen if you're using a newly released version of Xcode and Ingredients has not yet been updated to support it."];
            [alert addButtonWithTitle:@"Quit"];
            
            NSInteger answer = [alert runModal];
            
            NSString *appSupportPath = [@"~/Library/Application Support/Ingredients/" stringByExpandingTildeInPath];
            
            [[NSFileManager defaultManager] removeItemAtPath:appSupportPath error:nil];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"docsets"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ShutdownBad"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"storeVersion"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [NSApp terminate:nil];
        }
	});*/
}

- (void)finishedLoading
{
	NSManagedObjectContext *ctx = [appController backgroundManagedObjectContext];
	dispatch_queue_t queue = [appController backgroundQueue];
	NSLog(@"FINISHED LOADING: %d", queue);
	if (!queue)
		return;
	
	dispatch_async(queue, ^{
		
		//Oh god, Core Data was *NOT* meant to be used like this
		NSEntityDescription *docRecordEntity = [NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:ctx];
		NSPropertyDescription *nameProperty = [[docRecordEntity propertiesByName] valueForKey:@"name"];
		
		NSFetchRequest *fetchEverything = [[NSFetchRequest alloc] init];
		[fetchEverything setEntity:docRecordEntity];
		[fetchEverything setResultType:NSDictionaryResultType];
		[fetchEverything setReturnsDistinctResults:YES];
		[fetchEverything setPropertiesToFetch:[NSArray arrayWithObject:nameProperty]];
		
		
		id fu = [ctx fffffffuuuuuuuuuuuu];

		[[fu database] executeUpdate:@"CREATE INDEX IF NOT EXISTS fileability_docrecord_name ON ZDOCRECORD (ZNAME COLLATE NOCASE)"];

		FMResultSet *rset = [[fu database] executeQuery:@"SELECT DISTINCT ZNAME FROM ZDOCRECORD" withArgumentsInArray:[NSArray array]];
		//id objects = [fu magicObjectsForResultSet:rset];
		
		NSMutableArray *names = [[NSMutableArray alloc] init];
		while ([rset next])
		{
			id name = [rset stringForColumnIndex:0];
			if (name)
				[names addObject:name];
		}
		
		
		[rset close];
	/*
		
		NSArray *objects = [ctx executeFetchRequest:fetchEverything error:nil];
	*/	
		NSLog(@"[names count] = %d", [names count]);
        if ([names count] < 10)
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Ingredients could not find any documentation to index."];
                [alert setInformativeText:@"This is usually because Xcode has not downloaded documentation. Try going to Xcode's Documentation preferences and making sure the docsets you want have been downloaded.\n\nThis can also happen if you're using a newly released version of Xcode and Ingredients has not yet been updated to support it."];
                [alert addButtonWithTitle:@"Quit"];
                
                NSInteger answer = [alert runModal];
                
                NSString *appSupportPath = [@"~/Library/Application Support/Ingredients/" stringByExpandingTildeInPath];
                /*
                [[NSFileManager defaultManager] removeItemAtPath:appSupportPath error:nil];
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"docsets"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ShutdownBad"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"storeVersion"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                */
                [NSApp terminate:nil];
                    return;
            });
        }
                
		NSLog(@"All names: %d", [names count]);
		
		IGKWordMembership *wordMembershipManager = [IGKWordMembership sharedManagerWithCapacity:[names count]];
		NSCharacterSet *uppercaseCharacters = [NSCharacterSet uppercaseLetterCharacterSet];
		for (NSString *name in names)
		{
			if (![name length])
				continue;
			
			unichar firstLetter = [name characterAtIndex:0];
			
			//To avoid littering the documents with links, we only want to include names that start with an uppercase letter
			if (firstLetter < 'A' || firstLetter > 'Z')
				continue;
			
			[wordMembershipManager addWord:name];
		}
		
		NSLog(@"Unique uppercase names: %d", [[wordMembershipManager valueForKey:@"words"] count]);
	});
	
}

- (double)fraction
{
	return (double)pathsCounter / (double)totalPathsCount;
}

- (void)addDocsetsInPath:(NSString *)docsets toArray:(NSMutableArray *)docsetPaths set:(NSMutableSet *)docsetsSet developerDirectory:(NSString *)devDir
{
	NSError *error = nil;
	NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docsets error:&error];
	if (error)
		return;
	
	if (![paths count])
		return;
	
	NSMutableArray *docsetPathsArray = [[NSMutableArray alloc] initWithCapacity:[paths count]];
	
	NSMutableDictionary *container = [[NSMutableDictionary alloc] init];
	[container setValue:devDir forKey:@"developerDirectory"];
	[container setValue:docsetPathsArray forKey:@"docsetPaths"];
	
	for (NSString *path in paths)
	{
		if ([path isEqual:@"com.apple.ADC_Reference_Library.DeveloperTools.docset"])
			continue;
		
		path = [docsets stringByAppendingPathComponent:path];
		if (![path length] || ![[path pathExtension] isEqual:@"docset"])
			continue;
		
		if ([docsetsSet containsObject:path])
			continue;
        
		[docsetPathsArray addObject:path];
		[docsetsSet addObject:path];
	}
	
	if (![docsetPathsArray count])
		return;
	
	[docsetPaths addObject:container];
}

- (void)finalize
{
	dispatch_release(dbQueue);
	[super finalize];
}

@end
