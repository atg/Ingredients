//
//  IGKFrecencyStore.h
//  Ingredients
//
//  Created by Alex Gordon on 01/07/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import "IGKCircularBuffer.h"

@interface IGKFrecencyStore : NSObject {
	NSString *identifier;
	IGKCircularBuffer buffer;
	
	BOOL hasChanges;
}

+ (id)storeWithIdentifier:(NSString *)identifier;

- (void)recordItem:(NSString *)item;
- (NSArray *)timestampsForItem:(NSString *)item count:(uint64_t *)count;

@end
