//
//  IGKManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 08/04/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKManagedObject : NSManagedObject {

}

- (BOOL)isKindOfEntityNamed:(NSString *)entityName;
- (BOOL)hasKey:(NSString *)key;
- (id)valueForSoftKey:(NSString *)key;

@end
