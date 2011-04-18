#import "IGKTabBrowser.h"
#import "IGKTabContents.h"
#import "IGKTabController.h"

@implementation IGKTabBrowser

// This method is called when a new tab is being created. We need to return a
// new CTTabContents object which will represent the contents of the new tab.
-(CTTabContents*)createBlankTabBasedOn:(CTTabContents*)baseContents {
  // Create a new instance of our tab type
  return [[[IGKTabController alloc]
      initWithBaseTabContents:baseContents] autorelease];
}
-(CTToolbarController *)createToolbarController
{
	return nil;
}
@end
