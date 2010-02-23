//
//  IGKMultiSelector.h
//  Ingredients
//
//  Created by Alex Gordon on 22/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
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
