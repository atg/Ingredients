//
//  Ingredients_AppDelegate.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright Fileability 2010 . All rights reserved.
//

#import "Ingredients_AppDelegate.h"
#import "PFMoveApplication.h"

@implementation Ingredients_AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	PFMoveToApplicationsFolderIfNecessary();
	
	[kitController showWindow:nil];
}

- (id)kitController
{
	return kitController;
}

@end
