//
//  IGKHTMLGenerator.h
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKDocRecordManagedObject.h"

@class IGKFullScraper;


//Generates HTML for display in the webview

typedef enum {
	IGKHTMLDisplayType_All = 1,
	
	IGKHTMLDisplayType_Overview = 1 << 1,
	IGKHTMLDisplayType_Tasks = 1 << 2,
	IGKHTMLDisplayType_Properties = 1 << 3,
	IGKHTMLDisplayType_Methods = 1 << 4,
	IGKHTMLDisplayType_Notifications = 1 << 5,
	IGKHTMLDisplayType_Delegate = 1 << 6,
} IGKHTMLDisplayType;

typedef NSUInteger IGKHTMLDisplayTypeMask;

@interface IGKHTMLGenerator : NSObject
{
	NSManagedObjectContext *context;
	NSManagedObjectContext *transientContext;
	
	IGKDocRecordManagedObject *managedObject;
	IGKDocRecordManagedObject *transientObject;
	
	IGKHTMLDisplayType displayType;
	
	BOOL isMethodContainer;
	
	
	NSMutableString *outputString;
	
	IGKFullScraper *fullScraper;
}

@property (assign) NSManagedObjectContext *context;
@property (assign) IGKDocRecordManagedObject *managedObject;
@property (assign) IGKHTMLDisplayType displayType;

- (NSString *)html;

- (IGKHTMLDisplayTypeMask)displayTypes;

@end
