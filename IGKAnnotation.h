//
//  IKGAnnotation.h
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IKGAnnotation : NSObject {
	NSString *docurl;
	NSString *submitter_name;
	NSString *uuid;
	NSString *annotation;
}

@property (assign) NSString *docurl;
@property (assign) NSString *submitter_name;
@property (assign) NSString *uuid;
@property (assign) NSString *annotation;

}


@end
