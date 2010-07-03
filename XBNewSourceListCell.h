//
//  XBNewSourceListCell.h
//  SourceList3
//
//  Created by Alex Gordon on 16/01/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>

extern NSString *const XBSourceListLabelRed;
extern NSString *const XBSourceListLabelOrange;
extern NSString *const XBSourceListLabelYellow;
extern NSString *const XBSourceListLabelGreen;
extern NSString *const XBSourceListLabelBlue;
extern NSString *const XBSourceListLabelPurple;
extern NSString *const XBSourceListLabelGray;
extern NSString *const XBSourceListLabelClear;
extern NSString *const XBSourceListLabelNA;

typedef NSString XBSourceListLabel;

@interface XBNewSourceListCell : NSTextFieldCell {
	XBSourceListLabel *label;
	BOOL isHighlighted;
	
	NSImage *image;
	NSImage *alternateImage;
	
	NSTableView *tableView;
	
	//0 not used, 1 normal, -1 hover, 2 clicked
	int actionButtonState;
	
	BOOL hasAddButton;
	
	BOOL hasCloseButton;
}

@property (assign) NSTableView *tableView;

@property (assign) XBSourceListLabel *label;
@property (assign) BOOL isHighlighted;

@property (assign) NSImage *image;
@property (assign) NSImage *alternateImage;

@property (assign) int actionButtonState;

@property (assign) BOOL hasAddButton;
@property (assign) BOOL hasCloseButton;

@end
