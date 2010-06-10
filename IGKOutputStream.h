//
//  IGKOutputStream.h
//  Ingredients
//
//  Created by Alex Gordon on 09/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKOutputStream : NSOutputStream {

}

- (void)appendString:(NSString *)str;

- (NSString *)stringValue;

@end
