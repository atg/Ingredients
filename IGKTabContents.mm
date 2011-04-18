#import "IGKTabContents.h"
#import "common.h"

@implementation IGKTabContents
/*
-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
  if (!(self = [super initWithBaseTabContents:baseContents])) return nil;

  // Setup our contents -- a scrolling text view

  // Create a simple NSTextView
  NSTextView* tv = [[NSTextView alloc] initWithFrame:NSZeroRect];
  [tv setFont:[NSFont userFixedPitchFontOfSize:13.0]];
  [tv setAutoresizingMask:                  NSViewMaxYMargin|
                          NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|
                                           NSViewHeightSizable|
                                           NSViewMinYMargin];

  // Create a NSScrollView to which we add the NSTextView
  NSScrollView *sv = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  [sv setDocumentView:tv];
  [sv setHasVerticalScroller:YES];

  // Set the NSScrollView as our view
  self.view = sv;

  return self;
}

-(void)viewFrameDidChange:(NSRect)newFrame {
  // We need to recalculate the frame of the NSTextView when the frame changes.
  // This happens when a tab is created and when it's moved between windows.
  [super viewFrameDidChange:newFrame];
  NSClipView* clipView = [[view_ subviews] objectAtIndex:0];
  NSTextView* tv = [[clipView subviews] objectAtIndex:0];
  NSRect frame = NSZeroRect;
  frame.size = [(NSScrollView*)(view_) contentSize];
  [tv setFrame:frame];
}
*/

@end
