//
//  IGKPreferencesController.m
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKPreferencesController.h"

@interface IGKPreferencesController ()

- (void)switchToView:(NSView *)view item:(NSToolbarItem *)toolbarItem animate:(BOOL)animate;

- (void)addDeveloperDirectoryPath:(NSString *)path;
- (void)reloadTableViews;
- (void)saveChanges;

@end

@implementation IGKPreferencesController

@synthesize startIntoDocsets;

- (id)init
{
	if (self = [super initWithWindowNibName:@"IGKPreferences"])
	{
		developerDirectories = [[NSMutableArray alloc] init];
		docsets = [[NSMutableArray alloc] init];
				
		[self reloadTableViews];
	}
	
	return self;
}
- (void)windowDidLoad
{
	[self reloadTableViews];
	[self switchToView:startIntoDocsets ? docsetsView : generalView item:generalToolbarItem animate:NO];

	if (startIntoDocsets)
	{
		[[[self window] toolbar] setSelectedItemIdentifier:@"Docsets"];
	}
}
- (void)showWindow:(id)sender
{
	[[self window] center];
	
	[super showWindow:sender];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[[NSApp delegate] kitController] managedObjectContext];
}

#pragma mark Tab Switching

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Docsets", @"Updates", nil];
}

//Tab switching
- (IBAction)switchToGeneral:(id)sender
{
	[self switchToView:generalView item:generalToolbarItem animate:YES];
}
- (IBAction)switchToDocsets:(id)sender
{
	[self switchToView:docsetsView item:docsetsToolbarItem animate:YES];
}
- (IBAction)switchToUpdates:(id)sender
{
	[self switchToView:updatesView item:updatesToolbarItem animate:YES];
}
- (void)switchToView:(NSView *)view item:(NSToolbarItem *)toolbarItem animate:(BOOL)animate
{
	[[[self window] toolbar] setSelectedItemIdentifier:[toolbarItem itemIdentifier]];
	
	[currentView removeFromSuperview];
	
	[view setFrameOrigin:NSZeroPoint];
	[[[self window] contentView] addSubview:view];
	
	currentView = view;
	
	CGFloat borderHeight = [[self window] frame].size.height - [[[self window] contentView] frame].size.height;
	
	NSRect newWindowFrame = [[self window] frame];
	newWindowFrame.size.height = [view frame].size.height + borderHeight;
	newWindowFrame.origin.y += [[self window] frame].size.height - newWindowFrame.size.height;
	
	[[self window] setFrame:newWindowFrame display:YES animate:animate];
}

- (void)reloadTableViews
{
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"developerDirectories"])
		developerDirectories = [[[NSUserDefaults standardUserDefaults] valueForKey:@"developerDirectories"] mutableCopy];
	
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"docsets"])
		docsets = [[[NSUserDefaults standardUserDefaults] valueForKey:@"docsets"] mutableCopy];
	
	[developerDirectoriesTableView reloadData];
	[docsetsTableView reloadData];
}

#pragma mark Docsets Logic

- (void)selectedFilterDocsetForPath:(NSString *)path
{	
	BOOL changedSomething = NO;
	
	for (NSDictionary *docset in [docsets copy])
	{
		BOOL isDocset = [[docset valueForKey:@"path"] isEqual:path];
		
		if ([[docset valueForKey:@"isSelected"] boolValue] != isDocset)
		{			
			NSDictionary *newDocset = [docset mutableCopy];
			[newDocset setValue:[NSNumber numberWithBool:isDocset] forKey:@"isSelected"];
			
			[docsets replaceObjectAtIndex:[docsets indexOfObject:docset] withObject:newDocset];
			
			changedSomething = YES;
		}
	}
	
	if (changedSomething)
	{
		[self saveChangesNeedsRelaunch:NO];
		
		[self reloadTableViews];
	}
}

- (NSString *)selectedFilterDocsetPath
{
	for (NSDictionary *docset in docsets)
	{
		if ([[docset valueForKey:@"isSelected"] boolValue])
		{
			return [docset valueForKey:@"path"];
		}
	}
	
	return nil;
}

- (IBAction)addDeveloperDirectory:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton)
			return;
		
		NSString *path = [[openPanel URL] path];
		
		//Sanity check path. If it really is a Developer directory, it should have a Library/version.plist
		NSString *versionPlistPath = [path stringByAppendingPathComponent:@"Library/version.plist"];
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:versionPlistPath];
		if (!exists)
		{
			NSBeep();
			return;
		}
		
		[self addDeveloperDirectoryPath:path];
		
		[self reloadTableViews];
	}];
}
- (void)addDeveloperDirectoryPath:(NSString *)path
{
	NSMutableDictionary *devDir = [[NSMutableDictionary alloc] init];
	[devDir setValue:path forKey:@"path"];
	
	for (NSDictionary *dict in developerDirectories)
	{
		if ([[dict valueForKey:@"path"] isEqual:path])
			return;
	}
	
	[developerDirectories addObject:devDir];
	[self saveChanges];
}
- (int)addDocsetWithPath:(NSString *)path localizedUserInterfaceName:(NSString *)localizedUserInterfaceName developerDirectory:(NSString *)devDir
{
	NSMutableDictionary *docset = [[NSMutableDictionary alloc] init];
	[docset setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
	[docset setValue:path forKey:@"path"];
	[docset setValue:localizedUserInterfaceName forKey:@"name"];
	[docset setValue:devDir forKey:@"developerDirectory"];
	
	for (NSDictionary *dict in docsets)
	{
		if ([[dict valueForKey:@"path"] isEqual:path])
			return ([[dict valueForKey:@"isEnabled"] boolValue] ? 1 : 0);
	}
	
	[docsets addObject:docset];
	[self saveChanges];
	
	return -1;
}
- (IBAction)removeSelectedDeveloperDirectories:(id)sender
{
	NSIndexSet *selectedIndicies = [developerDirectoriesTableView selectedRowIndexes];
	if ([selectedIndicies count] >= [developerDirectories count])
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to remove all developer directories?" defaultButton:@"Remove" alternateButton:@"Don't Remove" otherButton:nil informativeTextWithFormat:@""];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(removeLastAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
	else
	{
		[self removeSelectedDeveloperDirectories];
	}
}
- (void)removeLastAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn)
	{
		[self removeSelectedDeveloperDirectories];
	}
}
- (void)removeSelectedDeveloperDirectories
{
	NSIndexSet *selectedIndicies = [developerDirectoriesTableView selectedRowIndexes];
	[developerDirectories removeObjectsAtIndexes:selectedIndicies];
	[self saveChanges];
	
	[self reloadTableViews];
}

- (void)saveChanges
{
	[self saveChangesNeedsRelaunch:NO];
}
- (void)saveChangesNeedsRelaunch:(BOOL)needsRelaunch
{
	BOOL devDirsChanged = NO;
	if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"developerDirectories"] isEqual:developerDirectories])
		devDirsChanged = YES;
	
	BOOL docsetsChanged = NO;
	if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"docsets"] isEqual:docsets])
		docsetsChanged = YES;
	
	[[NSUserDefaults standardUserDefaults] setValue:developerDirectories forKey:@"developerDirectories"];
	[[NSUserDefaults standardUserDefaults] setValue:docsets forKey:@"docsets"];
	
	if (needsRelaunch)
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needsReindex"];
	}
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if (needsRelaunch)
	{
		if (devDirsChanged || docsetsChanged)
			[[docsetsChangedStatusView animator] setHidden:NO];
	}
}
- (IBAction)relaunch:(id)sender
{
	Class SUUpdaterClass = NSClassFromString(@"SUUpdater");
	if (SUUpdaterClass == Nil)
		return;
	
	// Copy the relauncher into a temporary directory so we can get to it after the new version's installed.
	NSString *relaunchPath = nil;
	NSString *relaunchPathToCopy = [[NSBundle bundleForClass:SUUpdaterClass] pathForResource:@"relaunch" ofType:@""];
	if (![relaunchPathToCopy length])
		return;
	
	NSString *targetPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[relaunchPathToCopy lastPathComponent]];	
	if (![targetPath length])
		return;
	
	// Only the paranoid survive: if there's already a stray copy of relaunch there, we would have problems.
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
	if ([[NSFileManager defaultManager] copyItemAtPath:relaunchPathToCopy toPath:targetPath error:&error])
		relaunchPath = [targetPath retain];
	
	if (!relaunchPath || ![[NSFileManager defaultManager] fileExistsAtPath:relaunchPath])
	{
		NSBeep();
		return;
	}		
	
	NSString *pathToRelaunch = [[NSBundle mainBundle] bundlePath];
	[NSTask launchedTaskWithLaunchPath:relaunchPath arguments:[NSArray arrayWithObjects:pathToRelaunch, [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]], nil]];
	
	[NSApp terminate:self];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == developerDirectoriesTableView)
	{
		return [developerDirectories count];
	}
	else if (tableView == docsetsTableView)
	{
		return [docsets count];
	}
	
	return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == developerDirectoriesTableView)
	{
		NSString *path = [[developerDirectories objectAtIndex:row] valueForKey:@"path"];
		if ([[tableColumn identifier] isEqual:@"icon"])
		{
			//FIXME: We need proper icons for docsets and developer directories
			return [[NSWorkspace sharedWorkspace] iconForFile:path];
		}
		else if ([[tableColumn identifier] isEqual:@"path"])
		{
			return path;
		}
	}
	else if (tableView == docsetsTableView)
	{
		NSDictionary *docset = [docsets objectAtIndex:row];
		
		if ([[tableColumn identifier] isEqual:@"isEnabled"])
		{
			return [docset valueForKey:@"isEnabled"];
		}
		else if ([[tableColumn identifier] isEqual:@"icon"])
		{
			return [[NSWorkspace sharedWorkspace] iconForFile:[docset valueForKey:@"path"]];
		}
		else if ([[tableColumn identifier] isEqual:@"name"])
		{
			return [docset valueForKey:@"name"];
		}
		else if ([[tableColumn identifier] isEqual:@"developerDirectory"])
		{
			return [docset valueForKey:@"developerDirectory"];
		}
	}
	
	return nil;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == docsetsTableView)
	{
		if ([[tableColumn identifier] isEqual:@"isEnabled"])
		{
			NSDictionary *docset = [[docsets objectAtIndex:row] mutableCopy];
			[docset setValue:[NSNumber numberWithBool:[object boolValue]] forKey:@"isEnabled"];
			
			[docsets replaceObjectAtIndex:row withObject:docset];
			[self saveChangesNeedsRelaunch:YES];
			
			[self reloadTableViews];
		}
	}
}

/*
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	//Disallow selection for the docsets table view
	if (tableView == docsetsTableView && row != -1)
		return NO;
	
	return YES;
}
*/

#pragma mark Updates Logic

- (NSString *)appVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (IBAction)checkForUpdates:(id)sender
{
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
}

- (void)setUpdateMatrixTag:(NSInteger)updateMatrixTag
{
	if (updateMatrixTag == 1)
	{
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
		[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:YES];
	}
	else if (updateMatrixTag == 2)
	{
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
		[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:NO];
	}
	else //if (updateMatrixTag == 3)
	{
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
		[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:NO];
	}
}
- (NSInteger)updateMatrixTag
{
	BOOL checks = [[SUUpdater sharedUpdater] automaticallyChecksForUpdates];
	BOOL downloads = [[SUUpdater sharedUpdater] automaticallyDownloadsUpdates];
	
	if (checks && downloads)
		return 1;
	else if (checks && !downloads)
		return 2;
	else
		return 3;
}

#pragma mark Singleton

static IGKPreferencesController *sharedPreferencesController = nil;

+ (IGKPreferencesController *)sharedPreferencesController
{
    @synchronized(self) {
        if (sharedPreferencesController == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedPreferencesController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedPreferencesController == nil) {
            sharedPreferencesController = [super allocWithZone:zone];
            return sharedPreferencesController;  // assignment and return on first allocation
        }
    }
    return sharedPreferencesController; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
