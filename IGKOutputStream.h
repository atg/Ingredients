//
//  IGKOutputStream.h
//  Ingredients
//
//  Created by Alex Gordon on 09/06/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKOutputStream : NSOutputStream {

}

- (void)appendString:(NSString *)str;

- (NSString *)stringValue;

@end
