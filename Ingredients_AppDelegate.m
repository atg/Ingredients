//
//  Ingredients_AppDelegate.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright Fileability 2010 . Written in 2010 by Fileability..
//

#import "Ingredients_AppDelegate.h"
#import "PFMoveApplication.h"
@class IGKTabBrowser;

@implementation Ingredients_AppDelegate

- (id)init
{
	if (self = [super init])
	{
		NSLog(@"Welcome to Ingredients: Documentation at the speed of Core Data.");
		[NSApp setDelegate:self];
	}
	return self;
}

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSRunAlertPanel(@"GET URL", @"", @"", @"", @"");
}

- (void)lookupService:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSArray *types = [pboard types];
	if ([types containsObject:NSStringPboardType]){
		NSString* query = [pboard stringForType:NSStringPboardType];
		[kitController queryString: query];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{	
	NSLog(@"kitController = %@", kitController);
	srandom((unsigned long)[NSDate timeIntervalSinceReferenceDate]);
		
	[NSApp setServicesProvider:self];
	[kitController showWindow:nil];
	
	NSUpdateDynamicServices();
}
/*
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create a new browser & window when we start
    CTBrowserWindowController* windowController =
    [[CTBrowserWindowController alloc] initWithBrowser:[MyBrowser browser]];
    [windowController.browser addBlankTabInForeground:YES];
    [windowController showWindow:self];
    // Because window controller are owned by the app, we need to release our
    // reference.
    //[windowController autorelease];
}
 */

// When there are no windows in our application, this class (AppDelegate) will
// become the first responder. We forward the command to the browser class.
- (void)commandDispatch:(id)sender {
    [IGKTabBrowser executeCommand:[sender tag]];
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
