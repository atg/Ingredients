//
//  IGKPredicateEditor.h
//  Ingredients
//
//  Created by Alex Gordon on 23/03/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKPredicateEditor : NSPredicateEditor {
	NSString *requestedEntityName;
}

- (NSPredicate *)predicateWithEntityNamed:(NSString **)outEntityName;

@end
