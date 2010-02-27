//
//  IGKWindow.m
//  Ingredients
//
//  Created by Alex Gordon on 22/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKWindow.h"
#import "IGKMultiSelector.h"

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

@end
