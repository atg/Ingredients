//
//  IGKPreferencesController.h
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/SUUpdater.h>

@interface IGKPreferencesController : NSWindowController
{
	NSView *currentView;
	
	IBOutlet NSView *generalView;
	IBOutlet NSToolbarItem *generalToolbarItem;
	
	IBOutlet NSView *updatesView;
	IBOutlet NSToolbarItem *updatesToolbarItem;
}

//Tab switching
- (IBAction)switchToGeneral:(id)sender;
- (IBAction)switchToUpdates:(id)sender;

//Updates logic
- (IBAction)checkForUpdates:(id)sender;

- (void)setUpdateMatrixTag:(NSInteger)updateMatrixTag;
- (NSInteger)updateMatrixTag;

@end
