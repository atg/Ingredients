//
//  IGKWindowController.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKApplicationDelegate;

@interface IGKWindowController : NSWindowController
{
	IGKApplicationDelegate *appDelegate;
}

@property (assign) IGKApplicationDelegate *appDelegate;

@end
