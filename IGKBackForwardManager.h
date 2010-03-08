//
//  IGKBackForwardManager.h
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//This emulates WebBackForwardList for no particular reason

@interface IGKBackForwardManager : NSObject
{
	IBOutlet WebView *webView;
	IBOutlet id delegate;
	
	/* The backStack stores all WebHistoryItems we can go back to.
	   The forwardStack stores all WebHistoryItems we can go forward to.
	   When we go back we push currentItem onto backStack, and then pop an item off forwardStack and set it to current item. */
	
	NSMutableArray *backStack;
	WebHistoryItem *currentItem;
	NSMutableArray *forwardStack;
}

@property (assign) WebView *webView;
@property (assign) id delegate;

- (void)visitPage:(WebHistoryItem *)item;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

- (void)goBackBy:(NSInteger)amount;
- (void)goForwardBy:(NSInteger)amount;

- (BOOL)canGoBack;
- (BOOL)canGoForward;

- (NSArray *)backList;
- (WebHistoryItem *)backItem;
- (WebHistoryItem *)currentItem;
- (WebHistoryItem *)forwardItem;
- (NSArray *)forwardList;

@end
