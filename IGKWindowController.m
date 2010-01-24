//
//  IGKWindowController.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKWindowController.h"
#import "IGKApplicationDelegate.h"


@implementation IGKWindowController

@synthesize appDelegate;

- (NSString *)windowNibName
{
	return @"CHDocumentationBrowser";
}

- (void)windowDidLoad
{
	currentModeIndex = CHDocumentationBrowserUIMode_NeedsSetup;
	[self setMode:CHDocumentationBrowserUIMode_TwoUp];
}

- (void)close
{
	if ([appDelegate hasMultipleWindowControllers])
		[[appDelegate windowControllers] removeObject:self];
	
	[super close];
}

#pragma mark UI

- (void)setMode:(int)modeIndex
{
	//If we're already in this mode, bail
	if (modeIndex == currentModeIndex)
		return;
	
	if (currentModeIndex == CHDocumentationBrowserUIMode_TwoUp)
	{
		// two-up -> browser
		if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			
		}
		
		// two-up -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
	{
		// browser -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			
		}
		
		// browser -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		// search -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			
		}
		
		// search -> browser
		else if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_NeedsSetup)
	{
		//Set up subviews of the two-up view
		//Main
		[twoPaneView setFrame:[contentView bounds]];
		
		//Browser
		[browserView setFrame:[[[twoPaneSplitView subviews] objectAtIndex:1] bounds]];
		[[[twoPaneSplitView subviews] objectAtIndex:1] addSubview:browserView];
		
		//Side search
		[sideSearchView setFrame:[[[twoPaneContentsSplitView subviews] objectAtIndex:0] bounds]];
		[[[twoPaneContentsSplitView subviews] objectAtIndex:0] addSubview:sideSearchView];
		
		//Table of contents
		[tableOfContentsView setFrame:[[[twoPaneContentsSplitView subviews] objectAtIndex:1] bounds]];
		[[[twoPaneContentsSplitView subviews] objectAtIndex:1] addSubview:tableOfContentsView];
		
		
		//Set up the search view
		[searchView setFrame:[contentView bounds]];
		
		
		// none -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp || modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			[contentView addSubview:twoPaneView];
			
			// none -> browser
			if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
			{
				CGFloat leftWidth = [[[twoPaneContentsSplitView subviews] objectAtIndex:0] bounds].size.width;
				
				[twoPaneSplitView setEnabled:NO];
				
				NSRect newFrame = [twoPaneSplitView frame];
				newFrame.origin.x = - leftWidth - 1;
				newFrame.size.width = [twoPaneView frame].size.width + leftWidth + 1;
				[twoPaneSplitView setFrame:newFrame];
			}
		}
		
		//none -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			[contentView addSubview:searchView];
		}
	}
}


@end
