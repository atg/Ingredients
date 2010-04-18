//
//  IGKResizeDelegatedView.h
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKResizeDelegatedView : NSView {
	IBOutlet id resizeDelegate;
}

@property (assign) id resizeDelegate;

@end
