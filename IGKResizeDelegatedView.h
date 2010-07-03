//
//  IGKResizeDelegatedView.h
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKResizeDelegatedView : NSView {
	IBOutlet id resizeDelegate;
}

@property (assign) id resizeDelegate;

@end
