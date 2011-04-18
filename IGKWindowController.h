//
//  IGKTabController.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import <ChromiumTabs/ChromiumTabs.h>

@class CTBrowser;
@class IGKApplicationDelegate;


@interface IGKWindowController : CTBrowserWindowController
{
	IGKApplicationDelegate *appDelegate;
}

@property (assign) IGKApplicationDelegate *appDelegate;

- (void)newTabShouldIndex:(BOOL)shouldIndex;

@end