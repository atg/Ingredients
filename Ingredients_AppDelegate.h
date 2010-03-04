//
//  Ingredients_AppDelegate.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright Fileability 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IngredientsKit/IngredientsKit.h>

@interface Ingredients_AppDelegate : NSObject<NSApplicationDelegate>
{
	IBOutlet IGKApplicationDelegate *kitController;
}

- (id)kitController;

@end
