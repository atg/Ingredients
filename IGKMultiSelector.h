//
//  IGKMultiSelector.h
//  Ingredients
//
//  Created by Alex Gordon on 22/02/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKMultiSelector : NSButton {
	int mouseState;
	
	int oldSelectedCell;
	int selectedCell;
}

- (int)selectedCell;
- (void)setSelectedCell:(int)newSelectedCell;

- (void)drawCellNamed:(NSString *)name point:(NSPoint)point index:(int)index;

@end
