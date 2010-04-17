//
//  NSXMLNode+IGKAdditions.h
//  Ingredients
//
//  Created by Alex Gordon on 05/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLNode (IGKAdditions)

- (NSString *)commentlessStringValue;

//Private
- (void)innerCommentlessStringValueInto:(NSMutableString *)str;

- (NSArray *)nodesMatchingPredicate:(BOOL (^)(NSXMLNode*))predicate;

@end
