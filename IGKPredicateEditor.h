//
//  IGKPredicateEditor.h
//  Ingredients
//
//  Created by Alex Gordon on 23/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKPredicateEditor : NSPredicateEditor {
	NSString *requestedEntityName;
}

- (NSPredicate *)predicateWithEntityNamed:(NSString **)outEntityName;

@end
