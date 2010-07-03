//
//  CHLeftSplitView.h
//  Chocolat
//
//  Created by Alex Gordon on 29/10/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>

@interface CHLeftSplitView : BWSplitView {
	BOOL enabled;
}

@property (assign) BOOL enabled;

@end
