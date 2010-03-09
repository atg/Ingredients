#import "IngredientsCommand.h"

@implementation IngredientsSearchCommand

- (id)performDefaultImplementation
{
	[NSApp activateIgnoringOtherApps:YES];
	NSRunAlertPanel(@"IT WORKS", nil, nil, nil, nil);
	
	return nil;
}

@end

@implementation IngredientsVisitCommand

- (id)performDefaultImplementation
{
	[NSApp activateIgnoringOtherApps:YES];
	NSRunAlertPanel(@"IT WORKS 2", nil, nil, nil, nil);
	
	return nil;
}

@end
