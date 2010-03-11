//
//  IGKTableOfContentsView.h
//  Ingredients
//
//  Created by Alex Gordon on 06/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKEaseInOutAnimatedView.h"


typedef enum {
	
	IGKTableOfContentsTitleColumn,
	IGKTableOfContentsIconColumn,

} IGKTableOfContentsColumn;



@protocol IGKTableOfContentsDelegate <NSObject>

@required
- (NSInteger)numberOfRowsInTableOfContents;
- (id)valueForTableOfContentsColumn:(IGKTableOfContentsColumn)col row:(NSInteger)row;

@optional
- (void)tableOfContentsChangedSelection;

@end



@interface IGKTableOfContentsView : IGKEaseInOutAnimatedView {
	IBOutlet id<IGKTableOfContentsDelegate> delegate;
	IBOutlet NSMutableIndexSet *selectedRowIndexes;
	
	IBOutlet id splitView;
	
	NSInteger lastDraggedRow;
}

@property (assign) id<IGKTableOfContentsDelegate> delegate;
@property (readonly) NSIndexSet *selectedRowIndexes;

- (void)reloadData;
- (NSUInteger)rowIndexForPoint:(NSPoint)p;

- (BOOL)hasNoItems;
- (float)heightToFit;

@end