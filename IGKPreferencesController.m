//
//  IGKPreferencesController.m
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKPreferencesController.h"

@interface IGKPreferencesController ()

- (void)switchToView:(NSView *)view item:(NSToolbarItem *)toolbarItem animate:(BOOL)animate;

@end

@implementation IGKPreferencesController

- (id)init
{
	if (self = [super initWithWindowNibName:@"IGKPreferences"])
	{
		developerDirectories = [[NSMutableArray alloc] init];
		docsets = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)windowDidLoad
{
	[self reloadTableViews];
	[self switchToView:generalView item:generalToolbarItem animate:NO];
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
		developerDirectories = [[NSUserDefaults standardUserDefaults] valueForKey:@"developerDirectories"];
	
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"docsets"])
		docsets = [[NSUserDefaults standardUserDefaults] valueForKey:@"docsets"];
	
	[developerDirectoriesTableView reloadData];
	[docsetsTableView reloadData];
}

#pragma mark Docsets Logic

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
		
		NSMutableDictionary *devDir = [[NSMutableDictionary alloc] init];
		[devDir setValue:path forKey:@"path"];
		
		[developerDirectories addObject:devDir];
		[self saveChanges];
		
		[self reloadTableViews];
	}];
}
- (IBAction)removeSelectedDeveloperDirectories:(id)sender
{
	NSIndexSet *selectedIndicies = [developerDirectoriesTableView selectedRowIndexes];
	if ([selectedIndicies count] >= [developerDirectories count])
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to remove all developer directories?" defaultButton:@"Remove" alternateButton:@"Don't Remove" otherButton:nil informativeTextWithFormat:@"No documentation will be visible."];
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
	[[NSUserDefaults standardUserDefaults] setValue:developerDirectories forKey:@"developerDirectories"];
	[[NSUserDefaults standardUserDefaults] setValue:docsets forKey:@"docsets"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
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
			return [docset valueForKey:@"developerDirectoryPath"];
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
			[self saveChanges];
			
			[self reloadTableViews];
		}
	}
}

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

@end
