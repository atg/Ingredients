//
//  IGKManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 08/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKManagedObject : NSManagedObject {

}

- (BOOL)isKindOfEntityNamed:(NSString *)entityName;
- (BOOL)hasKey:(NSString *)key;
- (id)valueForSoftKey:(NSString *)key;

@end
