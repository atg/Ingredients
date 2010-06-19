//
//  NSArray+IGKAdditions.h
//  Ingredients
//
//  Created by Alex Gordon on 18/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (IGKAdditions)

- (NSArray *)igk_map:(id (^)(id obj))rule;
- (NSArray *)igk_filter:(BOOL (^)(id obj))predicate;

- (NSArray *)igk_firstObject;
- (NSArray *)igk_objectAtSoftIndex:(NSInteger)index;

@end
