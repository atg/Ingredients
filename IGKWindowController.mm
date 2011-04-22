#import "IGKWindowController.h"
#import "IGKTabController.h"

@implementation IGKWindowController

@synthesize appDelegate;

- (void)newTabShouldIndex:(BOOL)shouldIndex
{
	/*
	IGKWindowController *windowController = [[IGKWindowController alloc] init];
	windowController.appDelegate = self;
	[windowControllers addObject:windowController];
	
	[windowController newTabShouldIndex:isIndexing];
	[windowController showWindow:nil];
	
    tabController.shouldIndex = YES;
	*/
}


- (BOOL)hasToolbar
{
	toolbarController_ = nil;
	return NO;
}
// This method is called when a new tab is being created. We need to return a
// new CTTabContents object which will represent the contents of the new tab.
-(CTTabContents*)createBlankTabBasedOn:(CTTabContents*)baseContents {
  // Create a new instance of our tab type
  return [[[IGKTabController alloc] initWithBaseTabContents:baseContents] autorelease];
}


- (BOOL)isLionOrGreater
{
    return NSClassFromString(@"NSLinguisticTagger") != Nil;
}


- (NSWindow *)actualWindow
{
	//if (isInFullscreen)
	//	return [[[[[self browser] allTabContents] lastObject] view] window];
	
	return [self window];
}




- (id)actionForwardee
{
	return [[self browser] selectedTabContents];
}
- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return YES;
	if ([[self actionForwardee] respondsToSelector:aSelector])
		return YES;
	return NO;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return [super methodSignatureForSelector:aSelector];
	
	id forwardee = [self actionForwardee];
	if ([forwardee respondsToSelector:aSelector])
		return [forwardee methodSignatureForSelector:aSelector];
	
	return [super methodSignatureForSelector:aSelector];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	id forwardee = [self actionForwardee];
	
	if ([forwardee respondsToSelector:[anInvocation selector]])
	{
		[anInvocation invokeWithTarget:forwardee];
	}
	else
	{
		[super forwardInvocation:anInvocation];
	}
}


@end