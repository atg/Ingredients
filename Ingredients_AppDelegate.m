//
//  Ingredients_AppDelegate.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright Fileability 2010 . Written in 2010 by Fileability..
//

#import "Ingredients_AppDelegate.h"
#import "PFMoveApplication.h"

@implementation Ingredients_AppDelegate

- (id)init
{
	if (self = [super init])
	{
		NSLog(@"INIT");
	}
	return self;
}

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSRunAlertPanel(@"GET URL", @"", @"", @"", @"");
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{	
	srandom((unsigned long)[NSDate timeIntervalSinceReferenceDate]);
	PFMoveToApplicationsFolderIfNecessary();
	
	[kitController showWindow:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	[kitController showWindow:nil];
	return YES;
}

- (id)kitController
{
	return kitController;
}

#pragma mark --- Applescript support ---
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	if ([key isEqualToString:@"orderedWindows"])
		return YES;
	else
		return NO;
}

//NSApplication's default implementation for this ends up returning a bunch of offscreen
//windows and such, but we only want to return documentation windows, so we override that here
- (NSArray*)orderedWindows
{
	return [kitController valueForKeyPath:@"windowControllers.window"];
}

@end
