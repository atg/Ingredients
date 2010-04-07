//
//  IGKDocSetManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKManagedObject.h"

@interface IGKDocSetManagedObject : IGKManagedObject {

}

- (NSString *)docsetURLHost;

//A localized name of the docset, in a way that is suitable for the UI
- (NSString *)localizedUserInterfaceName;

- (NSString *)shortPlatformName;
- (NSString *)shortVersionName;

@end
