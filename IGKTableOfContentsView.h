//
//  IGKTableOfContentsView.h
//  Ingredients
//
//  Created by Alex Gordon on 06/03/2010.
//  Written in 2010 by Fileability.
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
@property (readonly) NSMutableIndexSet *selectedRowIndexes;

- (void)reloadData;
- (NSUInteger)rowIndexForPoint:(NSPoint)p;

- (BOOL)hasNoItems;
- (float)heightToFit;

@end