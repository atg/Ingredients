//
//  IGKWindow.m
//  Ingredients
//
//  Created by Alex Gordon on 22/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKWindow.h"
#import "IGKMultiSelector.h"

@class IGKTabController;

@implementation IGKWindow

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(NSUInteger)styleMask 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag 
{
    if (self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:flag])
	{
#if 0
		NSSize addButtonSize = NSMakeSize(91, 22);
		multiSelector = [[IGKMultiSelector alloc] initWithFrame:NSMakeRect(contentRect.size.width-addButtonSize.width, contentRect.size.height, addButtonSize.width, addButtonSize.height)];
		[multiSelector setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
		//[multiSelector setImage:[NSImage imageNamed:@"window_frame_add_button"]];
		[[[self contentView] superview] addSubview:multiSelector];
#endif
	}
	
	return self;
}

#pragma mark --- Applescript support ---
- (id)handleSearchScriptCommand:(NSScriptCommand*)scriptCommand
{
	NSString* searchString = nil;
	
	searchString = [[scriptCommand arguments] objectForKey:@"searchString"];
	NSAssert(searchString != nil, @"No search string found for search script command");
	[(IGKTabController*)[self windowController] executeSearchWithString:searchString];
	return nil;
}

@end
