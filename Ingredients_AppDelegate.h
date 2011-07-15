//
//  Ingredients_AppDelegate.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright Fileability 2010 . Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>
//#import <IngredientsKit/IngredientsKit.h>
#import "IGKApplicationDelegate.h"

@interface Ingredients_AppDelegate : NSObject<NSApplicationDelegate>
{
	IBOutlet IGKApplicationDelegate *kitController;
}

- (id)kitController;

@end
