//
//  IGKMatteButton.h
//  Ingredients
//
//  Created by Alex Gordon on 19/06/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKMatteButton : NSButton {
	int mouseState;
	
	int oldSelectedCell;
	int selectedCell;
}

@end
