//
//  IGKSometimesCenteredTextCell.h
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//This isn't hacky at all. Not... at... all...

@interface IGKStrikethroughTextCell : NSTextFieldCell {
	BOOL hasStrikethrough;
}

@property (assign) BOOL hasStrikethrough;

@end

@interface IGKSometimesCenteredTextCell : IGKStrikethroughTextCell {

}

@end

@interface IGKSometimesCenteredTextCell2 : IGKStrikethroughTextCell {
	
}

@end
