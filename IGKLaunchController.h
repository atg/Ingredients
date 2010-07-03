//
//  IGKLaunchController.h
//  Ingredients
//
//  Created by Alex Gordon on 10/02/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>

@class IGKApplicationDelegate;

// This class manages the initial startup of Ingredients.
// It first checks if indexing is needed, if so it indexes and sends out a notification when done

@interface IGKLaunchController : NSObject
{
	IGKApplicationDelegate *appController;
	dispatch_queue_t dbQueue;
	
	NSMutableArray *scrapers;
	
	NSInteger pathReportsExpected;
	NSInteger pathReportsReceived;
	
	NSInteger pathsCounter;
	NSInteger totalPathsCount;
}

@property (assign) IGKApplicationDelegate *appController;

- (BOOL)launch;

- (double)fraction;

- (void)reportPathCount:(NSUInteger)pathCount;
- (void)reportPath;

@end
