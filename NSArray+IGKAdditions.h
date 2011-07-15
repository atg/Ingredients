//
//  NSArray+IGKAdditions.h
//  Ingredients
//
//  Created by Alex Gordon on 18/06/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (IGKAdditions)

- (NSArray *)igk_map:(id (^)(id obj))rule;
- (NSArray *)igk_filter:(BOOL (^)(id obj))predicate;

- (id)igk_firstObject;
- (id)igk_objectAtSoftIndex:(NSInteger)index;

@end
