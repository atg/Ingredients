//
//  IGKMatteButton.h
//  Ingredients
//
//  Created by Alex Gordon on 19/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKMatteButton : NSButton {
	int mouseState;
	
	int oldSelectedCell;
	int selectedCell;
}

@end
