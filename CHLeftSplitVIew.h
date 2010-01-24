//
//  CHLeftSplitView.h
//  Chocolat
//
//  Created by Alex Gordon on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>

@interface CHLeftSplitView : BWSplitView {
	BOOL enabled;
}

@property (assign) BOOL enabled;

@end
