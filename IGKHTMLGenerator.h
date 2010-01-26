//
//  IGKHTMLGenerator.h
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKDocRecordManagedObject.h"

//Generates HTML for display in the webview

typedef enum {
	IGKHTMLDisplayType_All,
	
	IGKHTMLDisplayType_Overview,
	IGKHTMLDisplayType_Tasks,
	IGKHTMLDisplayType_Properties,
	IGKHTMLDisplayType_Methods,
	IGKHTMLDisplayType_Notifications,
	IGKHTMLDisplayType_Delegate,
} IGKHTMLDisplayType;

@interface IGKHTMLGenerator : NSObject
{
	NSManagedObjectContext *context;
	
	IGKDocRecordManagedObject *managedObject;
	IGKHTMLDisplayType displayType;
	
	BOOL isMethodContainer;
}

@property (assign) NSManagedObjectContext *context;
@property (assign) IGKDocRecordManagedObject *managedObject;
@property (assign) IGKHTMLDisplayType displayType;

- (NSString *)html;

@end
