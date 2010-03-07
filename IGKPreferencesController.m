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
		
	}
	
	return self;
}
- (void)windowDidLoad
{
	[self switchToView:generalView item:generalToolbarItem animate:NO];
}
- (void)showWindow:(id)sender
{
	[[self window] center];
	
	[super showWindow:sender];
}

#pragma mark Tab Switching

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Updates", nil];
}

//Tab switching
- (IBAction)switchToGeneral:(id)sender
{
	[self switchToView:generalView item:generalToolbarItem animate:YES];
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
