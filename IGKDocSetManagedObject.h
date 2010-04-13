//
//  IGKDocSetManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKManagedObject.h"

NSString *IGKDocSetShortPlatformName(NSString *platformFamily);
NSString *IGKDocSetShortVersionName(NSString *platformVersion);
NSString *IGKDocSetLocalizedUserInterfaceName(NSString *platformFamily, NSString *version);

@interface IGKDocSetManagedObject : IGKManagedObject {

}

// macosx10.6.sdk
- (NSString *)sdkComponent;

// Mac/10.6
- (NSString *)docsetURLHost;

//A localized name of the docset, in a way that is suitable for the UI
- (NSString *)localizedUserInterfaceName;

- (NSString *)shortPlatformName;
- (NSString *)shortVersionName;

@end
