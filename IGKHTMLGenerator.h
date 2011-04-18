//
//  IGKHTMLGenerator.h
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

@class IGKDocRecordManagedObject;

@class IGKFullScraper;


//Generates HTML for display in the webview

typedef enum {
	//The table of contents should be hidden if the bit mask is a power of 2
	
	IGKHTMLDisplayType_None = 0,
	
	IGKHTMLDisplayType_All = 1,
	
	IGKHTMLDisplayType_Overview = 1 << 1,
	IGKHTMLDisplayType_Tasks = 1 << 2,
	IGKHTMLDisplayType_Properties = 1 << 3,
	IGKHTMLDisplayType_Methods = 1 << 4,
	IGKHTMLDisplayType_Notifications = 1 << 5,
	IGKHTMLDisplayType_Delegate = 1 << 6,
	IGKHTMLDisplayType_Misc = 1 << 7, //For miscellaneous things like structs, enums and consts
	
	IGKHTMLDisplayType_BindingListings = 1 << 8,
	
} IGKHTMLDisplayType;

typedef NSUInteger IGKHTMLDisplayTypeMask;

//Returns YES if mask is the set of one value. That is, if mask is a power of 2
BOOL IGKHTMLDisplayTypeMaskIsSingle(IGKHTMLDisplayTypeMask mask);

@interface IGKHTMLGenerator : NSObject
{
	NSManagedObjectContext *context;
	NSManagedObjectContext *transientContext;
	
	IGKDocRecordManagedObject *managedObject;
	IGKDocRecordManagedObject *transientObject;
	
	IGKHTMLDisplayTypeMask displayTypeMask;
	
	BOOL isMethodContainer;
	
	
	NSMutableString *outputString;
	
	IGKFullScraper *fullScraper;
}

@property (assign) NSManagedObjectContext *context;
@property (assign) IGKDocRecordManagedObject *managedObject;
@property (assign) IGKHTMLDisplayTypeMask displayTypeMask;

- (NSString *)html;

+ (BOOL)containsInDocument:(IGKDocRecordManagedObject *)mo transientObject:(NSManagedObject *)_transientObject displayTypeMask:(IGKHTMLDisplayTypeMask)_displayTypeMask containerName:(NSString *)containerName itemName:(NSString *)itemName ingrcode:(NSString *)ingrcode;
+ (NSString *)extractApplecodeFromHref:(NSString *)href itemName:(NSString **)itemName;
+ (NSString *)applecodeToIngrcode:(NSString *)applecode itemName:(NSString *)itemName;

- (id)transientObject;

- (IGKHTMLDisplayTypeMask)acceptableDisplayTypes;

@end

#ifdef __cplusplus
}
#endif 
