//
//  IGKScraper.m
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Written in 2010 by Fileability.
//

#import "IGKScraper.h"
#import "RegexKitLite.h"
#import "IGKDocRecordManagedObject.h"
#import "IGKLaunchController.h"
#import "NSXMLNode+IGKAdditions.h"
#import "NSString+Utilities.h"
#import "IGKDocSetManagedObject.h"

@interface IGKScraper ()

- (NSUInteger)backgroundSearch:(NSManagedObject *)docset;

+ (NSArray *)pathOfDeprecationAppendiciesForPath:(NSString *)indexPath;

- (NSManagedObject *)extractPath:(NSString *)extractPath relativeExtractPath:(NSString *)relativeExtractPath docset:(NSManagedObject *)docset isDeprecationAppendix:(BOOL)isDeprecationAppendix mainObjectIn:(NSManagedObject *)mainObjectIn;
- (NSManagedObject *)addRecordNamed:(NSString *)recordName entityName:(NSString *)entityName desc:(NSString *)recordDesc sourcePath:(NSString *)recordPath;

@end

@implementation IGKScraper

NSString *const kIGKDocsetPrefixPath = @"Contents/Resources/Documents/documentation";

- (id)initWithDocsetURL:(NSURL *)theDocsetURL managedObjectContext:(NSManagedObjectContext *)moc launchController:(IGKLaunchController*)lc dbQueue:(dispatch_queue_t)dbq developerDirectory:(NSString *)devDir
{
	if (self = [super init])
	{
		docsetURL = [theDocsetURL copy];
		docsetpath = [docsetURL path];
		url = [docsetURL URLByAppendingPathComponent:kIGKDocsetPrefixPath];
		ctx = moc;
		
		developerDirectory = devDir;
		
		launchController = lc;
		dbQueue = dbq;
	}
	
	return self;
}

- (BOOL)findPaths
{
	//Get the info.plist
	NSDictionary *infoPlist = [[NSDictionary alloc] initWithContentsOfURL:[docsetURL URLByAppendingPathComponent:@"Contents/Info.plist"]];
	NSLog(@"Finding paths for %@", docsetURL);
	NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
	
	
	//Reject Xcode documentation
	if (!bundleIdentifier || [bundleIdentifier isEqual:@"com.apple.adc.documentation.AppleXcode.DeveloperTools"])
		return NO;
	
	NSString *localizedUserInterfaceName = IGKDocSetLocalizedUserInterfaceName([infoPlist objectForKey:@"DocSetPlatformFamily"], [infoPlist objectForKey:@"DocSetPlatformVersion"]);
	
	//Register it with preferences
	int result = [[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] addDocsetWithPath:[docsetURL path]
																				      localizedUserInterfaceName:localizedUserInterfaceName
																						      developerDirectory:developerDirectory];
	/*
	 if result == -1
	 No docset already exists
	 if result == 0
	 Docset already exists but is disabled
	 if result == 1
	 Docset already exists and is enable
	 */
	if (result == 0)
	{
		return NO;
	}
	
	NSString *version = [infoPlist objectForKey:@"CFBundleVersion"];
	if (bundleIdentifier && version)
	{
		//Find out if we've already parsed
		NSPredicate *countPredicate = [NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and version == %@", bundleIdentifier, version];
		
		NSError *error = nil;
		NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity:[NSEntityDescription entityForName:@"Docset" inManagedObjectContext:ctx]];
		[fetch setPredicate:countPredicate];
		NSUInteger recordCount = [ctx countForFetchRequest:fetch error:&error];
		if (!error && recordCount > 0)
		{
			//There's already some records - don't parse
			NSLog(@"Docset already exists: %@ / %@", version, bundleIdentifier);
			return NO;
		}
	}
	
	
	
	//*** Create a docset object ***
	NSEntityDescription *docsetEntity = [NSEntityDescription entityForName:@"Docset" inManagedObjectContext:ctx];
	
	NSManagedObject *docset = [[IGKDocRecordManagedObject alloc] initWithEntity:docsetEntity insertIntoManagedObjectContext:ctx];
		
	if (bundleIdentifier)
		[docset setValue:bundleIdentifier forKey:@"bundleIdentifier"];
	if (version)
		[docset setValue:version forKey:@"version"];
	
	if ([infoPlist objectForKey:@"DocSetDescription"])
		[docset setValue:[infoPlist objectForKey:@"DocSetDescription"] forKey:@"docsetDescription"];
	if ([infoPlist objectForKey:@"DocSetFeedName"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFeedName"] forKey:@"feedName"];
	if ([infoPlist objectForKey:@"DocSetFeedURL"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFeedURL"] forKey:@"feedURL"];
	
	if ([infoPlist objectForKey:@"DocSetPlatformFamily"])
		[docset setValue:[infoPlist objectForKey:@"DocSetPlatformFamily"] forKey:@"platformFamily"];
	else if ([infoPlist objectForKey:@"DocSetFeedName"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFeedName"] forKey:@"platformFamily"];
	
	if ([infoPlist objectForKey:@"DocSetPlatformVersion"])
		[docset setValue:[infoPlist objectForKey:@"DocSetPlatformVersion"] forKey:@"platformVersion"];
	else if ([infoPlist objectForKey:@"CFBundleVersion"])
		[docset setValue:[infoPlist objectForKey:@"CFBundleVersion"] forKey:@"platformVersion"];
	
	if ([infoPlist objectForKey:@"DocSetFallbackURL"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFallbackURL"] forKey:@"fallbackURL"];
	
	[docset setValue:[docsetURL absoluteString] forKey:@"url"];
	[docset setValue:[docsetURL path] forKey:@"path"];
		
	scraperDocset = docset;
	paths = [[NSMutableArray alloc] init];
	
	return YES;
}
- (void)findPathCount
{
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
		pathsCount = [self backgroundSearch:scraperDocset];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[launchController reportPathCount:pathsCount];
		});
	});
}

- (NSUInteger)backgroundSearch:(NSManagedObject *)docset
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	NSString *urlpath = [url path];
	NSError *error = nil;
	NSArray *subpaths = [manager subpathsOfDirectoryAtPath:[url path] error:&error];
	if (error)
		return 0;
	
	unsigned count = 0;
	NSLog(@"subpaths = %d for %@", [subpaths count], docsetURL);
	for (NSString *subpath in subpaths)
	{
		//Ignore non-html files
		if (![[subpath pathExtension] isEqual:@"html"])
			continue;
		
		//Paths to exclude are added in order from most common to least common
		NSString *lastPathComponent = [subpath lastPathComponent];
		if ([lastPathComponent isEqual:@"toc.html"] ||
			[lastPathComponent isEqual:@"History.html"] ||
			[lastPathComponent isEqual:@"index_of_book.html"] ||
			[lastPathComponent isEqual:@"RevisionHistory.html"] ||
			[lastPathComponent isEqual:@"revision_history.html"] ||
			[subpath containsString:@"RefUpdate/"])
		{
			continue;
		}
		
		
		NSArray *pathcomps = [subpath pathComponents];
		NSSet *pathset = [NSSet setWithArray:pathcomps];
		if ([pathset member:@"Conceptual"] ||
			[pathset member:@"History"] ||
			[pathset member:@"DeveloperTools"] ||
			[pathset member:@"gcc"] ||
			[pathset member:@"qa"] ||
			[pathset member:@"samplecode"] ||
			[pathset member:@"gdb"] ||
			[pathset member:@"SafariWebContent"] ||
			[pathset member:@"FoundationRefUpdate"])
		{
			continue;
		}
		
		
		//If the path ends with index.html and Reference/Reference.html already exists, ignore
		//This is because some index.html files _should_ be parsed, but if a Reference/Reference.html exists, then it should not
		if ([lastPathComponent isEqual:@"index.html"])
		{
			NSString *dir = [urlpath stringByAppendingPathComponent:[subpath stringByDeletingLastPathComponent]];
			if ([manager fileExistsAtPath:[dir stringByAppendingPathComponent:@"Reference/Reference.html"]])
				continue;
			if ([manager fileExistsAtPath:[dir stringByAppendingPathComponent:@"CompositePage.html"]])
				continue;
		}
		
		count++;
		
		[paths addObject:subpath];
	}
	NSLog(@"\t Found paths = %d", [paths count]);
	
	return [paths count];
}
- (void)index
{
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSString *docsetPathWithPrefix = [docsetpath stringByAppendingPathComponent:kIGKDocsetPrefixPath];
		
		for (NSString *relativeExtractPath in paths)
		{
			NSString *indexPath = [docsetPathWithPrefix stringByAppendingPathComponent:relativeExtractPath];
			
			NSManagedObject *mainObject = [self extractPath:indexPath relativeExtractPath:relativeExtractPath docset:scraperDocset isDeprecationAppendix:NO mainObjectIn:nil];

			//Try to find matching deprecated appendicies			
			if (mainObject)
			{
				NSArray *deprecationAppendicies = [[self class] pathOfDeprecationAppendiciesForPath:indexPath];
				for (NSString *deprecationAppendixPath in deprecationAppendicies)
				{
					[self extractPath:[[[indexPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:deprecationAppendixPath]
				  relativeExtractPath:[[[relativeExtractPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:deprecationAppendixPath]
							   docset:scraperDocset
				isDeprecationAppendix:YES
						 mainObjectIn:mainObject];
				}
			}
			
			pathsCounter += 1;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[launchController reportPath];
			});
		}
	});
}
+ (NSArray *)pathOfDeprecationAppendiciesForPath:(NSString *)indexPath
{	
	if (![[indexPath pathComponents] containsObject:@"Reference"])
		return nil;
	
	NSString *deprecationAppendiciesFolder = [[[indexPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DeprecationAppendix"];
	
	NSError *err = nil;
	NSArray *appendixPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:deprecationAppendiciesFolder error:&err];
	
	if (![appendixPaths count])
		return nil;
	
	NSMutableArray *deprecationAppendicies = [[NSMutableArray alloc] initWithCapacity:[appendixPaths count]];
	
	for (NSString *deprecationAppendixPath in appendixPaths)
	{
		[deprecationAppendicies addObject:[@"DeprecationAppendix" stringByAppendingPathComponent:deprecationAppendixPath]];
	}
	
	return deprecationAppendicies;
}

- (NSManagedObject *)extractPath:(NSString *)extractPath relativeExtractPath:(NSString *)relativeExtractPath docset:(NSManagedObject *)docset isDeprecationAppendix:(BOOL)isDeprecationAppendix mainObjectIn:(NSManagedObject *)mainObjectIn
{	
	//Let's try to extract the class's name (assuming it is a class of course)	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:extractPath encoding:NSUTF8StringEncoding error:&error];
	NSUInteger contentsLength = [contents length];
	if (error || !contents)
	{
		return nil;
	}
	
	
	//Parse the item's name and kind
	NSString *regex_className = @"<a name=\"//apple_ref/(occ/([a-z_]+)/([a-zA-Z_][a-zA-Z0-9_\\(\\)]*)|c/([a-zA-Z_][a-zA-Z0-9_]*))";
	NSArray *className_captures = [contents captureComponentsMatchedByRegex:regex_className];
	if ([className_captures count] < 3)
	{
		return nil;
	}
	
	NSString *type = [className_captures objectAtIndex:2];
	NSString *name = [className_captures objectAtIndex:3];
	NSString *ctype = [className_captures objectAtIndex:4];
	
	/* Common types
	 cl		 - class
	 intf	 - protocol
	 instm	 - 
	 intfm	 - 
	 cat	 - category
	 binding - bindings listing
	 */
	
	enum {
		ParentItemType_ObjCClass,
		ParentItemType_ObjCCategory,
		ParentItemType_ObjCProtocol,
		ParentItemType_ObjCBindingsListing,
		ParentItemType_GenericCListing,
	} parentItemType;
	
	NSString *entityName = nil;
	if ([type isEqual:@"cl"])
	{
		entityName = @"ObjCClass";
		parentItemType = ParentItemType_ObjCClass;
	}
	
	else if ([type isEqual:@"cat"])
	{
		entityName = @"ObjCCategory";
		parentItemType = ParentItemType_ObjCCategory;
	}
	
	else if ([type isEqual:@"intf"])
	{
		entityName = @"ObjCProtocol";
		parentItemType = ParentItemType_ObjCCategory;
	}
	
	else if ([type isEqual:@"binding"])
	{
		entityName = @"ObjCBindingsListing";
		parentItemType = ParentItemType_ObjCBindingsListing;
	}
	
	//Otherwise we may have a listing of C functions, structs, typedefs, etc
	else if ([ctype length])
	{
		entityName = nil;
		parentItemType = ParentItemType_GenericCListing;
	}
	
	//Nothing of note matched
	else if (!isDeprecationAppendix)
	{
		// bail
		return nil;
	}
	
	//Superclass
	NSString *superclass = nil;
	if (parentItemType == ParentItemType_ObjCClass)
	{
		//Find the superclass
		NSString *superclassRegex = @"Inherits from.+?>([^<]+)<";
		
		NSArray *superclassCaptureSet = [contents captureComponentsMatchedByRegex:superclassRegex];
		if ([superclassCaptureSet count] >= 2)
		{
			superclass = [superclassCaptureSet objectAtIndex:1];
		}
	}
	
	//Conforms to
	NSMutableSet *conformsTo = nil;
	if (parentItemType == ParentItemType_ObjCClass || parentItemType == ParentItemType_ObjCProtocol)
	{
		NSString *conformsToRegex = @"Conforms to.+?</td>(.+?)</td>";
		NSArray *conformsToCaptureSet = [contents captureComponentsMatchedByRegex:conformsToRegex];
		if ([conformsToCaptureSet count] >= 2)
		{
			NSString *conformsToSubstring = [conformsToCaptureSet objectAtIndex:1];
			NSString *conformsToSubregex = @">([A-Za-z0-9_$]+)<";
			
			NSArray *arrayOfMatchesCaptures = [conformsToSubstring arrayOfCaptureComponentsMatchedByRegex:conformsToSubregex];
			if ([arrayOfMatchesCaptures count])
			{
				conformsTo = [[NSMutableSet alloc] initWithCapacity:[arrayOfMatchesCaptures count]];
				for (NSArray *conformsToCaptures in arrayOfMatchesCaptures)
				{
					if ([conformsToCaptures count] < 2)
						continue;
					
					NSString *n = [conformsToCaptures objectAtIndex:1];
					[conformsTo addObject:n];
				}
			}
			
			if ([conformsTo count] == 0)
				conformsTo = nil;
		}
	}
	
	//Availability to
	NSString *availability = nil;
	if (parentItemType == ParentItemType_ObjCClass || parentItemType == ParentItemType_ObjCProtocol)
	{
		NSString *availabilityRegex = @"<strong>Availability</strong>.+?<div>(.+?)</div>";
		NSArray *availabilityCaptureSet = [contents captureComponentsMatchedByRegex:availabilityRegex];
		if ([availabilityCaptureSet count] >= 2)
		{
			availability = [availabilityCaptureSet objectAtIndex:1];
		}
	}
	
	//Declared in
	NSString *declaredIn = nil;
	NSString *declaredInRegex = @"Declared in.+?<span class=\"content_text\">([^<]+)<";
	NSArray *declaredInCaptureSet = [contents captureComponentsMatchedByRegex:declaredInRegex];
	if ([declaredInCaptureSet count] >= 2)
	{
		declaredIn = [declaredInCaptureSet objectAtIndex:1];
	}
	
	NSString *linkRegex = @"name=\"//apple_ref/((occ/(instm|clm|intfm|intfcm|intfp|instp)/[a-zA-Z_:][a-zA-Z0-9:_]*/([a-zA-Z:_][a-zA-Z0-9:_]*))|(c/([a-zA-Z0-9_]+)/([a-zA-Z:_][a-zA-Z0-9:_]*)))\"([^<>]+role=\"([a-zA-Z0-9_]+)\")?";
	
	/* The interesting captures are 3 & 4, and 5 & 6 */
	NSArray *items = [contents arrayOfCaptureComponentsMatchedByRegex:linkRegex];
	__block NSManagedObject *obj = mainObjectIn;
	
	dispatch_sync(dbQueue, ^{
		
		NSEntityDescription *propertyEntity = [NSEntityDescription entityForName:@"ObjCProperty" inManagedObjectContext:ctx];
		NSEntityDescription *methodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:ctx];
		NSEntityDescription *notificationEntity = nil;
		
		NSEntityDescription *globalVariableEntity = nil;
		NSEntityDescription *constantEntity = nil;
		NSEntityDescription *functionEntity = nil;
		NSEntityDescription *macroEntity = nil;
		NSEntityDescription *typedefEntity = nil;
		NSEntityDescription *enumEntity = nil;
		NSEntityDescription *structEntity = nil;
		NSEntityDescription *unionEntity = nil;
				
		//If this isn't a deprecation appendix, create a parent object
		if (entityName && isDeprecationAppendix == NO)
		{
			obj = [self addRecordNamed:name entityName:entityName desc:@"" sourcePath:relativeExtractPath];
			[obj setValue:docset forKey:@"docset"];
			[obj setValue:[NSNumber numberWithUnsignedInteger:contentsLength] forKey:@"contentsLength"];			
			
			if ([superclass length])
			{
				[obj setValue:superclass forKey:@"superclassName"];
			}
			
			if ([availability length])
				[obj setValue:availability forKey:@"availability"];
			
			if ([declaredIn length])
				[obj setValue:declaredIn forKey:@"declared_in_header"];
			
			if ([conformsTo count])
			{
				NSString *conformsToString = [NSString stringWithFormat:@"=%@=", [[conformsTo allObjects] componentsJoinedByString:@"="]];
				[obj setValue:conformsToString forKey:@"conformsto"];
			}
		}
		
		int lastWasProperty = 0;
		for (NSArray *captures in items)
		{
			if ([captures count] > 4)
			{
				NSString *itemType = [captures objectAtIndex:3];
				NSString *itemName = [captures objectAtIndex:4];
				
				if ([itemType length] && [itemName length])
				{
					//Method
					BOOL isProperty = [itemType isEqual:@"intfp"] || [itemType isEqual:@"instp"];
					BOOL isInstanceMethod = isProperty || [itemType isEqual:@"instm"] || [itemType isEqual:@"intfm"];
					
					if (isProperty)
					{
						lastWasProperty = 1;
					}
					else if (lastWasProperty == 1)
					{
						lastWasProperty = 2;
						continue;
					}
					else if (lastWasProperty == 2)
					{
						lastWasProperty = 0;
						continue;
					}
					
					IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:isProperty ? propertyEntity : methodEntity insertIntoManagedObjectContext:ctx];
					
					[newMethod setValue:[itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
					[newMethod setValue:obj forKey:@"container"];
					[newMethod setValue:obj forKey:@"globalContainer"];
					[newMethod setValue:docset forKey:@"docset"];
					[newMethod setValue:relativeExtractPath forKey:@"documentPath"];
					if (isDeprecationAppendix)
						[newMethod setValue:[NSNumber numberWithBool:YES] forKey:@"isDeprecated"];
					
					if (!isProperty)
						[newMethod setValue:[NSNumber numberWithBool:isInstanceMethod] forKey:@"isInstanceMethod"];
					
					continue;
				}
			}
			
			if ([captures count] > 6)
			{
				NSString *itemType = [captures objectAtIndex:6];
				NSString *itemName = [captures objectAtIndex:7];
								
				NSString *itemRole = nil;
				if ([captures count] > 9)
					itemRole = [captures objectAtIndex:9];
				
				if ([itemType length] && [itemName length])
				{
					IGKDocRecordManagedObject *newSubobject = nil;
					
					/* Item types and examples:
						 tdef: vDSP_Length
						 
						 cl: IOFireWireAVCLibConsumerInterface
						 
						 econst: kFFTDirection_Forward
						 
						 macro: vDSP_Version0
						 
						 tag: kAXErrorSuccess
						 
						 func: AXNotificationHIObjectNotify
						 
						 instm: devicePairingConnecting:
						 
						 data: kAXAttachmentTextAttribute
					 */					 
					
					if ([itemType isEqual:@"tdef"])
					{
						NSEntityDescription *entity = nil;
						
						if ([itemRole isEqual:@"Enum"])
						{
							if (!enumEntity)
								enumEntity = [NSEntityDescription entityForName:@"CEnum" inManagedObjectContext:ctx];
							entity = enumEntity;
						}
						
						//These two don't actually exists... yet. The only role= attribute used is "Enum" (and "Macro", but that's kind of redundant but that's kind of redundant)
						else if ([itemRole isEqual:@"Struct"])
						{
							if (!structEntity)
								structEntity = [NSEntityDescription entityForName:@"CStruct" inManagedObjectContext:ctx];
							entity = structEntity;
						}
						else if ([itemRole isEqual:@"Union"])
						{
							if (!unionEntity)
								unionEntity = [NSEntityDescription entityForName:@"CUnion" inManagedObjectContext:ctx];
							entity = unionEntity;
						}
						else
						{
							if (!typedefEntity)
								typedefEntity = [NSEntityDescription entityForName:@"CTypedef" inManagedObjectContext:ctx];
							entity = typedefEntity;
						}
						
						newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
					}
					
					else if ([itemType isEqual:@"func"])
					{
						if (!functionEntity)
							functionEntity = [NSEntityDescription entityForName:@"CFunction" inManagedObjectContext:ctx];
						
						newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:functionEntity insertIntoManagedObjectContext:ctx];
					}
					
					else if ([itemType isEqual:@"macro"])
					{
						if (!macroEntity)
							macroEntity = [NSEntityDescription entityForName:@"CMacro" inManagedObjectContext:ctx];
						
						newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:macroEntity insertIntoManagedObjectContext:ctx];
					}
					
					//Weirdly, "constant_group" is Apple's code for a global and "data" is Apple's code for a constant *facepalm*
					else if ([itemType isEqual:@"constant_group"])
					{
						if (!globalVariableEntity)
							globalVariableEntity = [NSEntityDescription entityForName:@"CGlobal" inManagedObjectContext:ctx];
						
						newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:globalVariableEntity insertIntoManagedObjectContext:ctx];
					}
					
					else if ([itemType isEqual:@"econst"] || [itemType isEqual:@"data"] ||
							 [itemType isEqual:@"tag"]) //TODO: An item type of "tag" should really be a CEnumRecord entity
					{
						//This is such a hacky way to find out if an element is a notification, but it seems the most accurate way
						BOOL isNotification = ([itemType isEqual:@"data"] && [itemName hasSuffix:@"Notification"]);
						if (isNotification)
						{
							if (!notificationEntity)
								notificationEntity = [NSEntityDescription entityForName:@"ObjCNotification" inManagedObjectContext:ctx];
							
							newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:notificationEntity insertIntoManagedObjectContext:ctx];
							[newSubobject setValue:obj forKey:@"container"];
							[newSubobject setValue:obj forKey:@"globalContainer"];
						}
						else
						{
							if (!constantEntity)
								constantEntity = [NSEntityDescription entityForName:@"CConstant" inManagedObjectContext:ctx];
							
							newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:constantEntity insertIntoManagedObjectContext:ctx];
						}
					}
					
					if (newSubobject)
					{
						[newSubobject setValue:[itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
						[newSubobject setValue:docset forKey:@"docset"];
						[newSubobject setValue:obj forKey:@"miscContainer"];
						[newSubobject setValue:relativeExtractPath forKey:@"documentPath"];
						
						if (isDeprecationAppendix)
							[newSubobject setValue:[NSNumber numberWithBool:YES] forKey:@"isDeprecated"];
					}
					
					continue;
				}
			}
		}
	
	});
	
	return obj;
}

- (NSManagedObject *)addRecordNamed:(NSString *)recordName entityName:(NSString *)entityName desc:(NSString *)recordDesc sourcePath:(NSString *)recordPath
{	
	NSEntityDescription *ed = [NSEntityDescription entityForName:entityName inManagedObjectContext:ctx];
	
	NSManagedObject *newRecord = [[IGKDocRecordManagedObject alloc] initWithEntity:ed insertIntoManagedObjectContext:ctx];
	
	[newRecord setValue:[recordName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
	[newRecord setValue:recordDesc forKey:@"overview"];
	[newRecord setValue:recordPath forKey:@"documentPath"];
	
	return newRecord;
}


@end


@interface IGKFullScraper ()

+ (NSArray *)splitArray:(NSArray *)array byBlock:(NSString* (^)(id a))block;
+ (NSArray *)array:(NSArray *)array findObjectByBlock:(BOOL (^)(id a))block;

- (void)createMethodNamed:(NSString *)name description:(NSString *)description prototype:(NSString *)prototype
			 methodEntity:(NSEntityDescription *)methodEntity parent:(NSManagedObject*)parent docset:(NSManagedObject*)theDocset;

- (void)scrape;
- (void)scrapeTransientObject;
- (void)scrapeMethod;
- (void)scrapeAbstractMethodContainer;
- (void)scrapeMethodChildren:(NSArray *)children index:(NSUInteger)index managedObject:(NSManagedObject *)object;
- (void)scrapeBindings:(NSArray *)children index:(NSUInteger)index managedObject:(NSManagedObject *)object;

- (void)scrapeApplecode:(NSString *)applecode;
- (void)scrapeApplecodes:(NSArray *)applecodes;;

@end


@implementation IGKFullScraper

@synthesize transientObject;
@synthesize transientContext;

- (id)initWithManagedObject:(IGKDocRecordManagedObject *)persistentObject
{
	if (self = [super init])
	{
		persistobj = persistentObject;
	}
	
	return self;
}

- (void)start
{
	//Create a new managed object context to put the results of the full scrape into
	//We don't want to actually -save: the results 
	transientContext = [[NSManagedObjectContext alloc] init];
	[transientContext setPersistentStoreCoordinator:[[persistobj managedObjectContext] persistentStoreCoordinator]];
	[transientContext setUndoManager:nil];
	
	//Scrape
	[self scrape];
}

- (void)cleanUp
{
	//Reset the context
	[transientContext rollback];
	[transientContext reset];
}

- (void)scrape
{
	NSManagedObjectContext *persistmoc = [persistobj managedObjectContext];
	NSError *err = nil;
	
	NSString *docsetPath = [[persistobj valueForKey:@"docset"] valueForKey:@"path"];
	NSString *docsetPathWithPrefix = [docsetPath stringByAppendingPathComponent:kIGKDocsetPrefixPath];
	
	//Fetch the deprecated methods
	NSFetchRequest *deprecatedObjectsFetch = [[NSFetchRequest alloc] init];
	[deprecatedObjectsFetch setEntity:[NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:persistmoc]];
	[deprecatedObjectsFetch setPredicate:[NSPredicate predicateWithFormat:@"isDeprecated=TRUE && globalContainer=%@", persistobj]];
	NSArray *deprecatedObjects = [persistmoc executeFetchRequest:deprecatedObjectsFetch error:&err];
	NSMutableSet *deprecatedAppendices = [[NSMutableSet alloc] initWithCapacity:1];
	for (NSManagedObject *deprecatedObject in deprecatedObjects)
	{
		NSString *deprecatedAppendixPath = [[deprecatedObject valueForKeyPath:@"heavyNonQueryables"] valueForKey:@"documentPath"];
		if (deprecatedAppendixPath)
			[deprecatedAppendices addObject:[docsetPathWithPrefix stringByAppendingPathComponent:deprecatedAppendixPath]];
	}
	
	//Get persistobj's equivalent in transientContext
	transientObject = (IGKDocRecordManagedObject *)[transientContext objectWithID:[persistobj objectID]];
	docset = [transientObject valueForKey:@"docset"];
	
	[self scrapeInPath:[docsetPathWithPrefix stringByAppendingPathComponent:[persistobj valueForKey:@"documentPath"]]];
	
	isParsingDeprecatedAppendix = YES;
	for (NSString *deprecatedAppendix in deprecatedAppendices)
	{
		[self scrapeInPath:deprecatedAppendix];
	}
	isParsingDeprecatedAppendix = NO;
}
- (void)scrapeInPath:(NSString *)extractPath
{
	//NSString *relativeExtractPath = [transientObject valueForKey:@"documentPath"];
	//NSString *extractPath = [docsetPathWithPrefix stringByAppendingPathComponent:relativeExtractPath];
	
	NSURL *fileurl = [NSURL fileURLWithPath:extractPath];
	
	NSError *err = nil;
	
	NSCache *xmlDocCache = [[[NSApp delegate] kitController] xmlDocumentCache];
	doc = [xmlDocCache objectForKey:fileurl];
	
	if (!doc)
	{
		doc = [[NSXMLDocument alloc] initWithContentsOfURL:fileurl options:NSXMLDocumentTidyHTML error:&err];
		[xmlDocCache setObject:doc forKey:fileurl cost:0];
		if (!doc)
			return;
	}
	
	methodNodes = nil;
	
	[self scrapeTransientObject];
}
- (NSArray *)methodNodes
{
	if (methodNodes)
		return methodNodes;
	
	methodNodes = [[doc rootElement] nodesMatchingPredicate:^BOOL(NSXMLNode *node) {
		return [[node name] isEqual:@"a"];
	}];
	
	return methodNodes;
}
- (void)scrapeTransientObject
{
	//Depending on the type of obj, we will need to parse it differently	
	if ([transientObject isKindOfEntityNamed:@"ObjCAbstractMethodContainer"])
	{
		[self scrapeAbstractMethodContainer];
		
		//Hacky way to also read new data for misc items
		if (!isParsingDeprecatedAppendix)
		{
			id oldTransientObject = transientObject;
			for (IGKDocRecordManagedObject *miscItem in [oldTransientObject valueForKey:@"miscitems"])
			{
				transientObject = miscItem;
				[self scrapeTransientObject];
			}
			transientObject = oldTransientObject;
		}
		return;
	}
	if ([transientObject isKindOfEntityNamed:@"ObjCMethod"] || [transientObject isKindOfEntityNamed:@"ObjCProperty"])
	{
		[self scrapeMethod];
	}
	else if ([transientObject isKindOfEntityNamed:@"CFunction"])
	{
		[self scrapeApplecode:@"c/func"];
	}
	else if ([transientObject isKindOfEntityNamed:@"CTypedef"])
	{
		[self scrapeApplecode:@"c/tdef"];
	}
	else if ([transientObject isKindOfEntityNamed:@"CStruct"])
	{
		[self scrapeApplecode:@"c/tdef"];
	}
	else if ([transientObject isKindOfEntityNamed:@"CEnum"])
	{
		[self scrapeApplecode:@"c/tdef"];
	}
	else if ([transientObject isKindOfEntityNamed:@"CMacro"])
	{
		[self scrapeApplecode:@"c/macro"];
	}
	else if ([transientObject isKindOfEntityNamed:@"CConstant"])
	{
		[self scrapeApplecodes:[NSArray arrayWithObjects:@"c/econst", @"c/data", @"c/tag", nil]];
	}
	else if ([transientObject isKindOfEntityNamed:@"CGlobal"])
	{
		[self scrapeApplecode:@"c/constant_group"];
	}
	else if ([transientObject isKindOfEntityNamed:@"ObjCNotification"])
	{
		[self scrapeApplecode:@"c/data"];
	}
	else if ([transientObject isKindOfEntityNamed:@"ObjCBindingsListing"])
	{
		[self scrapeBindingsListing];
	}
}

- (void)scrapeApplecode:(NSString *)applecode
{
	[self scrapeApplecodes:[NSArray arrayWithObject:applecode]];
}
- (void)scrapeApplecodes:(NSArray *)applecodes
{
	NSMutableArray *fullApplecodePatterns = [[NSMutableArray alloc] init];
	for (NSString *applecode in applecodes)
	{
		[fullApplecodePatterns addObject:[NSString stringWithFormat:@"//apple_ref/%@", applecode]];
	}
	
	//Search through all anchors in the document, and record their parent elements
	NSArray *mnodes = [self methodNodes];
	//NSMutableSet *containersSet = [[NSMutableSet alloc] initWithCapacity:[mnodes count]];
	NSHashTable *containersSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsOpaquePersonality capacity:[mnodes count]];
	for (NSXMLElement *a in mnodes)
	{
		if ([containersSet containsObject:[a parent]])
			continue;
		
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSXMLNode *el = [a attributeForLocalName:@"name"];
		NSString *strval = [el commentlessStringValue];
		
		//(instm|clm|intfm|intfcm|intfp|instp)
		for (NSString *fullApplecodePattern in fullApplecodePatterns)
		{
			if ([strval hasPrefix:fullApplecodePattern])
			{
				NSString *methodName = [transientObject valueForKey:@"name"];
				
				//This is a bit ropey
				if ([strval hasSuffix:methodName])
				{					
					[containersSet addObject:[a parent]];
					
					NSArray *children = [[a parent] children];
					NSInteger index = [children indexOfObject:a];
					if (index != -1)
					{
						[self scrapeMethodChildren:children index:index managedObject:transientObject];
					}
					
					break;
				}
			}
		}
	}
}
- (void)scrapeMethod
{
	NSError *err = nil;
	
	//NSArray *methodNodes1 = [[doc rootElement] nodesForXPath:@"//a" error:&err];
	
	//Search through all anchors in the document, and record their parent elements
	NSArray *mnodes = [self methodNodes];
	NSHashTable *containersSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsOpaquePersonality capacity:[mnodes count]];
	for (NSXMLElement *a in mnodes)
	{
		if ([containersSet containsObject:[a parent]])
			continue;
		
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
						
		NSXMLNode *el = [a attributeForLocalName:@"name"];
		NSString *strval = [el commentlessStringValue];
		
		//(instm|clm|intfm|intfcm|intfp|instp)
		if ([strval hasPrefix:@"//apple_ref/occ/instm"] || [strval hasPrefix:@"//apple_ref/occ/clm"] ||
			[strval hasPrefix:@"//apple_ref/occ/intfm"] || [strval hasPrefix:@"//apple_ref/occ/intfcm"] ||
			[strval hasPrefix:@"//apple_ref/occ/intfp"] || [strval hasPrefix:@"//apple_ref/occ/instp"])
		{
			NSString *methodName = [transientObject valueForKey:@"name"];
			
			//This is a bit ropey
			if ([strval length] >= [methodName length] && [[strval substringFromIndex:[strval length] - [methodName length]] isEqual:methodName])
			{
				[containersSet addObject:[a parent]];
				
				NSArray *children = [[a parent] children];
				NSInteger index = [children indexOfObject:a];
				if (index != -1)
				{
					
					[self scrapeMethodChildren:children index:index managedObject:transientObject];
				}
			}
		}
	}
}
- (void)scrapeMethodChildren:(NSArray *)children index:(NSUInteger)index managedObject:(NSManagedObject *)object
{
	/* Things we need to scrape
	     * name
	     * overview
	     * parameters
	     * returnType
	     * returnDescription
	     * availability
	     * seealsos
	     * samplecode
	*/
		
	BOOL hasRecordedMethod = NO;
	
	NSUInteger i = 0;
	NSUInteger count = [children count];
		
	BOOL isOnlyAElements = YES;
	if (count == 0)
		isOnlyAElements = NO;
	
	NSString *objlowername = [[object valueForKey:@"name"] lowercaseString];
	
	for (i = index; i < count; i++)
	{
		NSXMLElement *n = [children objectAtIndex:i];
		if (![n isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *nName = [[n name] lowercaseString];
		NSArray *nClass = [[[[n attributeForLocalName:@"class"] commentlessStringValue] lowercaseString] componentsSeparatedByString:@" "];
		
		if (![nName isEqual:@"a"])
			isOnlyAElements = NO;
		
		//name
		// <h3 class="*jump*"> ... </h3>
		if ([nName isEqual:@"h3"] && [nClass containsObject:@"jump"])
		{
			//If we've already recorded a method, then we're done
			if (hasRecordedMethod)
				break;
			hasRecordedMethod = YES;

			[object setValue:[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
			
			if (isParsingDeprecatedAppendix)
				[object setValue:[NSNumber numberWithBool:YES] forKey:@"isDeprecated"];
			
			continue;
		}
		
		//constants
		//This is what it SHOULD look like
		/* <a name="//apple_ref/c/econst/NSJapaneseEUCStringEncoding" title="NSJapaneseEUCStringEncoding"></a>
		   <a name="//apple_ref/doc/c_ref/NSJapaneseEUCStringEncoding" title="NSJapaneseEUCStringEncoding"></a>
		   <a name="//apple_ref/doc/uid/20000154-SW64" title="NSJapaneseEUCStringEncoding"></a>
		   <a name="//apple_ref/doc/uid/20000154-DontLinkElementID_204"></a>
		 
		   <dt>
		     <code class="jump constantName">NSJapaneseEUCStringEncoding</code>
		   </dt>
		   <dd>
		     <p>8-bit EUC encoding for Japanese text.</p>
		     <p>Available in Mac OS X v10.0 and later.</p>
		     <p>Declared in <code>NSString.h</code>.</p>
		   </dd>
		*/
		
		//This is what the "tidied" version looks like
		/* <dd>
		     <a name="//apple_ref/c/econst/NSJapaneseEUCStringEncoding" title="NSJapaneseEUCStringEncoding"></a>
		     <a name="//apple_ref/doc/c_ref/NSJapaneseEUCStringEncoding" title="NSJapaneseEUCStringEncoding"></a>
		     <a name="//apple_ref/doc/uid/20000154-SW64" title="NSJapaneseEUCStringEncoding"></a>
		     <a name="//apple_ref/doc/uid/20000154-DontLinkElementID_204"></a>
		   </dd>
		   <dt>
		     <code class="jump constantName">NSJapaneseEUCStringEncoding</code>
		   </dt>
		   <dd>
		     <p>8-bit EUC encoding for Japanese text.</p>
		     <p>Available in Mac OS X v10.0 and later.</p>
		     <p>Declared in <code>NSString.h</code>.</p>
		   </dd>		 
		 */
		
		if (i + 1 < count && [nName isEqual:@"dt"])
		{
			BOOL isConstant = NO;
			for (NSXMLElement *m in [n children])
			{
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				if (![[[m name] lowercaseString] isEqual:@"code"])
					continue;
				
				NSArray *mclasses = [[[[m attributeForLocalName:@"class"] commentlessStringValue] lowercaseString] componentsSeparatedByString:@" "];
				if (![mclasses containsObject:@"jump"])
					continue;
				
				if (![[[m commentlessStringValue] lowercaseString] isEqual:objlowername])
					break;
				
				isConstant = YES;
			}
						
			NSXMLElement *dd = [children objectAtIndex:i + 1];
			do
			{
				//Make sure this is a definition list for a full blown item
				if (!isConstant)
					break;
				if (![dd isKindOfClass:[NSXMLElement class]])
					break;
				if (![[[dd name] lowercaseString] isEqual:@"dd"])
					break;
								
				//Loop over child <p>s				
				NSArray *children = [dd children];
				for (NSXMLElement *p in children)
				{
					if (![p isKindOfClass:[NSXMLElement class]])
						continue;
					
					NSString *pStr = [p commentlessStringValue];
					if (![pStr length])
						continue;

					if ([pStr caseInsensitiveHasPrefix:@"Available"])
					{
						//Available in...
						[object setValue:pStr forKey:@"availability"];
					}
					else if ([pStr caseInsensitiveHasPrefix:@"Declared in"])
					{
						//Declared in...
						[object setValue:pStr forKey:@"declared_in_header"];
					}
					else
					{
						[object setValue:pStr forKey:@"overview"];
					}
				}
								
			} while (NO);
		}
		
		//overview
		// <p class="spaceabove"> ... </p> <p class="spaceabove"> ... </p> ...
		if ([nClass containsObject:@"spaceabove"] || [nClass containsObject:@"abstract"])
		{
			NSMutableString *overview = [[NSMutableString alloc] init];
			[overview appendFormat:@"<p>%@</p>", [n commentlessStringValue]];
			
			NSUInteger j;
			for (j = i + 1; j < count; j++)
			{
				NSXMLElement *m = [children objectAtIndex:j];
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				
				NSString *mclass = [[m attributeForLocalName:@"class"] commentlessStringValue];
				if (![mclass isEqual:@"spaceabove"] && ![mclass isEqual:@"abstract"])
					break;
				
				[overview appendFormat:@"<p>%@</p>", [m commentlessStringValue]];
			}
						
			[object setValue:overview forKey:@"overview"];
			continue;
		}
		
		//signature (methods only)
		// <p class="spaceabovemethod"> ... </p>
		if ([nClass containsObject:@"spaceabovemethod"] || [nClass containsObject:@"zshareddeclarationblockjavaobjc"])
		{
			NSMutableString *prototype = [[NSMutableString alloc] init];
			[prototype appendString:[n commentlessStringValue]];
			
			[object setValue:prototype forKey:@"signature"];
			continue;
		}
		
		//signature (other items)
		// <pre class="declaration">
		else if (([nName isEqual:@"pre"] || [nName isEqual:@"p"] || [nName isEqual:@"div"]) && [nClass containsObject:@"declaration"])
		{
			NSMutableString *prototype = [[NSMutableString alloc] init];
			[prototype appendString:[n commentlessStringValue]];
			
			[object setValue:prototype forKey:@"signature"];
			continue;
		}
		
		//parameters
		void (^parseParameters)(NSUInteger, NSArray *) = ^(NSUInteger j, NSArray *parentChildren) {
			if ([parentChildren count])
			{
				NSXMLElement *o = [parentChildren objectAtIndex:j];
				
				NSArray *nChildren = [o children];
				NSString *lastDT = nil;
				
				NSUInteger ind = 1;
				
				for (NSXMLElement *m in nChildren)
				{
					if ([[[m name] lowercaseString] isEqual:@"dt"])
					{
						lastDT = [m commentlessStringValue];
					}
					else if ([lastDT length] && [[[m name] lowercaseString] isEqual:@"dd"])
					{
						NSString *dd = [m commentlessStringValue];
						
						if ([dd length])
						{
							if (![object isKindOfEntityNamed:@"Callable"])
								break;
							
							if (!ParameterEntity)
								ParameterEntity = [NSEntityDescription entityForName:@"Parameter" inManagedObjectContext:transientContext];
							
							NSManagedObject *parameter = [[NSManagedObject alloc] initWithEntity:ParameterEntity insertIntoManagedObjectContext:transientContext];
							[parameter setValue:[NSNumber numberWithShort:ind] forKey:@"positionIndex"];
							[parameter setValue:[lastDT stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
							[parameter setValue:dd forKey:@"overview"];
							[parameter setValue:object forKey:@"callable"];
							
							ind++;
						}
						
						lastDT = nil;
					}
				}
			}
			
		};
		
		//Old
		/* <dl class="termdef">
		       <dt> ... name ... </dt>
		       <dd> ... overview ... </dd>
		   </dl>
		 */
		if ([nName isEqual:@"dl"] && [nClass containsObject:@"termdef"])
		{
			parseParameters(i, children);
			continue;
		}
		
		//New
		/* <div class="api parameters">
		     <h5>Parameters</h5>
		     <dl class="termdef">
		       <dt> ... name ... </dt>
		       <dd> ... overview ... </dd>
		     </dl>
		 </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"api"] && [nClass containsObject:@"parameters"])
		{
			parseParameters(1, [n children]);
		}
		
		
		//returnType
		// ???
		
		//returnDescription
		/* <div class="return_value">
			   <p> ... </p> <p> ... </p> ...
		   </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"return_value"])
		{
			NSArray *nChildren = [n children];
			NSMutableString *returnValueDescription = [[NSMutableString alloc] init];
			
			for (NSXMLElement *m in nChildren)
			{
				if (![[[m name] lowercaseString] isEqual:@"p"])
					continue;
				
				[returnValueDescription appendString:[m commentlessStringValue]];
			}
			
			[object setValue:returnValueDescription forKey:@"returnDescription"];
			continue;
		}
		
		//discussion
		void (^parseDiscussion)(NSUInteger, NSArray *) = ^(NSUInteger j, NSArray *nchildren) {
			NSMutableString *discussion = [[NSMutableString alloc] init];
			NSUInteger nchildrenCount = [nchildren count];
			
			for (; j < nchildrenCount; j++)
			{
				NSXMLElement *m = [nchildren objectAtIndex:j];
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				
				if ([[[m name] lowercaseString] isEqual:@"div"])
				{
					//This could be a codesample
					NSArray *divClass = [[[[m attributeForLocalName:@"class"] commentlessStringValue] lowercaseString] componentsSeparatedByString:@" "];
					if (![divClass containsObject:@"codesample"])
						break;
					
					[object setValue:[m commentlessStringValue] forKey:@"codesample"];
					continue;
				}
				
				NSString *mLowerName = [[m name] lowercaseString];
				if ([mLowerName isEqual:@"p"])
				{
					[discussion appendFormat:@"<p>%@</p>", [m commentlessStringValue]];
				}
				else if ([mLowerName isEqual:@"ul"])
				{
					for (NSXMLNode *li in [m children])
					{
						if (![li isKindOfClass:[NSXMLElement class]])
							continue;
						
						[discussion appendFormat:@"<p>- %@</p>", [li commentlessStringValue]];
					}
				}
				else
				{
					break;
				}
			}
			
			[object setValue:discussion forKey:@"discussion"];
		};
		
		//Old
		/* <h5>Discussion</h5>
		   <p> ... </p>
		   <p> ... </p>
		   ...
		 */
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isEqual:@"discussion"])
		{
			parseDiscussion(i + 1, children);
		}
		
		//New
		/* <div class="api discussion">
		     <h5>Discussion</h5>
		     <p> ... </p>
		     <p> ... </p>
		     ...
		   </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"api"] && [nClass containsObject:@"discussion"])
		{
			parseDiscussion(1, [n children]);
		}
		
				
		//availability
		/* <div class="Availability">
			   <ul class="availability">
				   <li class="availability"> ... </li>
			   </ul>
		   </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"availability"])
		{
			for (NSXMLElement *ul in [n children])
			{
				if ([[[ul name] lowercaseString] isEqual:@"ul"])
				{
					//TODO: This doesn't handle multiple availabilities. Should it? Does any docfile actually define those?
					
					NSArray *ulChildren = [ul children];
					for (NSXMLElement *ulChild in ulChildren)
					{
						[object setValue:[ulChild commentlessStringValue] forKey:@"availability"];
						
						break;
					}
					
					continue;
				}
			}
		}
		
		//seealsos
		void (^parseSeealsos)(NSUInteger, NSArray *) = ^(NSUInteger j, NSArray *parentChildren) {
			if ([parentChildren count])
			{
				NSXMLElement *ul = [parentChildren objectAtIndex:j];
				if ([[[ul name] lowercaseString] isEqual:@"ul"])
				{				
					for (NSXMLElement *li in [ul children])
					{
						NSXMLElement *codeElement = [[li children] lastObject];
						NSXMLElement *a = [[codeElement children] lastObject];
						
						if (![a isKindOfClass:[NSXMLElement class]])
							continue;
						NSString *href = [[a attributeForLocalName:@"href"] commentlessStringValue];
						NSString *strval = [a commentlessStringValue];
						
						if (!href || !strval)
							continue;
						
						if (!SeeAlsoEntity)
							SeeAlsoEntity = [NSEntityDescription entityForName:@"SeeAlso" inManagedObjectContext:transientContext];
						
						NSManagedObject *seealso = [[NSManagedObject alloc] initWithEntity:SeeAlsoEntity insertIntoManagedObjectContext:transientContext];
						[seealso setValue:href forKey:@"href"];
						strval = [strval stringByReplacingOccurrencesOfString:@"\u2013" withString:@"-"];
						
						[seealso setValue:[strval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
						[seealso setValue:object forKey:@"container"];
					}
				}
			}
		};
		
		/* <h5 class="tight">See Also</h5>
		   <ul class="availability">
			   <li class="availability">
				   <code>
					   <a href=" ... ">&#8211;&#xA0; ... </a>
				   </code>
			   </li>
		   </ul>
		 */
		//Old
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isEqual:@"see also"])
		{			
			parseSeealsos(i + 1, children);
		}
		//New
		if ([nName isEqual:@"div"] && [nClass containsObject:@"api"] && [nClass containsObject:@"seealso"])
		{
			parseSeealsos(1, [n children]);
		}
		
		//samplecodeprojects
		void (^parseSamplecodeprojects)(NSUInteger, NSArray *) = ^(NSUInteger j, NSArray *parentChildren) {
			if ([parentChildren count])
			{
				NSXMLElement *ul = [parentChildren objectAtIndex:j];
				if ([[[ul name] lowercaseString] isEqual:@"ul"])
				{				
					for (NSXMLElement *li in [ul children])
					{					
						NSXMLElement *spanElement = [[li children] lastObject];
						NSXMLElement *a = [[spanElement children] lastObject];
						
						NSString *href = [[a attributeForLocalName:@"href"] commentlessStringValue];
						NSString *strval = [a commentlessStringValue];
						
						if (!href || !strval)
							continue;
						
						if (!SampleCodeProjectEntity)
							SampleCodeProjectEntity = [NSEntityDescription entityForName:@"SampleCodeProject" inManagedObjectContext:transientContext];
						
						NSManagedObject *seealso = [[NSManagedObject alloc] initWithEntity:SampleCodeProjectEntity insertIntoManagedObjectContext:transientContext];
						[seealso setValue:href forKey:@"href"];
						[seealso setValue:[strval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
						[seealso setValue:object forKey:@"container"];
					}
				}
			}
		};
		/* <h5 class="tight">Related Sample Code</h5>
		   <ul class="availability">
			
		   <li class="availability">
		       <span class="content_text">
		           <a href=" ... "> ... </a>
		       </span>
		   </li>
		 
		   <li class="availability">
		       <span class="content_text">
		           <a href=" ... "> ... </a>
		       </span>
			</li>
		   
		   ...
		   
		 </ul>
		*/
		//Old
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] containsString:@"sample code"])
		{			
			parseSamplecodeprojects(i + 1, children);
		}
		
		//New
		//FIXME: For some reason <div class="api relatedSampleCode"> isn't being parsed into children, so this doesn't work for some elements. Yet to work out why it isn't parsed.
		if ([nName isEqual:@"div"] && [nClass containsObject:@"api"] && [nClass containsObject:@"relatedsamplecode"])
		{
			parseSamplecodeprojects(1, [n children]);
		}
		
		
		//declared_in_header
		/* <div class="DeclaredIn">
		       <h5 class="tight">Declared In</h5>
		       <code class="HeaderFile"> ... </code>
		   </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"declaredin"])
		{
			NSArray *nChildren = [n children];
			
			for (NSXMLElement *m in nChildren)
			{
				if (![[[m name] lowercaseString] isEqual:@"code"])
					continue;
				
				[object setValue:[m commentlessStringValue] forKey:@"declared_in_header"];
				break;
			}
			
			continue;
		}
		
		//specialConsiderations
		/* <h5 class="tight">Special Considerations</h5>
		 <p> ... </p>
		 <p> ... </p>
		 ...
		 */
		void (^parseSpecialConsiderations)(NSUInteger, NSArray *) = ^(NSUInteger j, NSArray *parentChildren) {
			if ([parentChildren count])
			{
				NSMutableString *specialConsiderations = [[NSMutableString alloc] init];
				
				for (; j < [parentChildren count]; j++)
				{
					NSXMLElement *m = [parentChildren objectAtIndex:j];
					if (![m isKindOfClass:[NSXMLElement class]])
						continue;
					if (![[[m name] lowercaseString] isEqual:@"p"])
						break;
					
					[specialConsiderations appendFormat:@"<p>%@</p>", [m commentlessStringValue]];
				}
				
				[object setValue:specialConsiderations forKey:@"specialConsiderations"];
			}
		};
		
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isEqual:@"special considerations"])
		{
			parseSpecialConsiderations(i + 1, children);
		}
		else if ([nName isEqual:@"div"] && [nClass containsObject:@"api"] && [nClass containsObject:@"specialconsiderations"])
		{
			parseSpecialConsiderations(1, [n children]);
		}
	}
		
	if (isOnlyAElements)
	{
		NSXMLElement *firstChild = [children objectAtIndex:0];
		if (![firstChild respondsToSelector:@selector(parent)])
			return;
		
		NSXMLElement *parent = (NSXMLElement *)[firstChild parent];
		if (![parent respondsToSelector:@selector(parent)])
			return;
		
		NSXMLElement *grandparent = (NSXMLElement *)[parent parent];
		if (![parent respondsToSelector:@selector(children)])
			return;
		
		[self scrapeMethodChildren:[grandparent children] index:0 managedObject:object];		
	}
}
- (void)scrapeAbstractMethodContainerTopDOMChildren:(NSArray *)children index:(NSUInteger)index type:(int)t
{
	NSUInteger i = 0;
	NSUInteger count = [children count];
	
	NSUInteger taskgroupPositionIndex = 1;
	
	for (i = index; i < count; i++)
	{
		NSXMLElement *n = [children objectAtIndex:i];
		if (![n isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *nName = [[n name] lowercaseString];
		NSArray *nClass = [[[[n attributeForLocalName:@"class"] commentlessStringValue] lowercaseString] componentsSeparatedByString:@" "];
		
		/*
			t = 0: Overview
			t = 1: Tasks
		 */
		
		//Overview
		if (t == 0)
		{
			//overview
			/* <p class="abstract"> ... </p>
			   <p> ... </p>
			   <p> ... </p>
			   ...
			 */
			if ([nName isEqual:@"p"] && [nClass containsObject:@"abstract"])
			{
				NSMutableString *overview = [[NSMutableString alloc] init];
				
				NSUInteger j;
				for (j = i; j < count; j++)
				{
					NSXMLElement *m = [children objectAtIndex:j];
					if (![m isKindOfClass:[NSXMLElement class]])
						continue;
					if (![[[m name] lowercaseString] isEqual:@"p"])
						break;
					
					[overview appendFormat:@"<p>%@</p>", [m commentlessStringValue]];
				}
				
				[transientObject setValue:overview forKey:@"overview"];
			}
		}
		
		//Tasks
		else if (t == 1)
		{
			//taskgroups
			/* <h3 class="tasks"> ... </h3>
			   <ul class="tooltip">
			      <li>
			         <span class="tooltip">
			            <code>
			               <a href=" ... "> ... </a>
			            </code>
			         </span>
			      </li>
			   </ul>
			 */
			
			if (i + 1 < count && [nName isEqual:@"h3"] && [nClass containsObject:@"tasks"])
			{			
				NSXMLElement *ul = [children objectAtIndex:i + 1];
				if ([[[ul name] lowercaseString] isEqual:@"ul"])
				{
					if (!MetaTaskGroupEntity)
						MetaTaskGroupEntity = [NSEntityDescription entityForName:@"MetaTaskGroup" inManagedObjectContext:transientContext];
					
					NSManagedObject *taskgroup = [[NSManagedObject alloc] initWithEntity:MetaTaskGroupEntity insertIntoManagedObjectContext:transientContext];
					[taskgroup setValue:[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
					[taskgroup setValue:[NSNumber numberWithInt:taskgroupPositionIndex] forKey:@"positionIndex"];
					[taskgroup setValue:transientObject forKey:@"container"];
					taskgroupPositionIndex++;
					
					NSUInteger taskgroupItemPositionIndex = 1;
					for (NSXMLElement *li in [ul children])
					{					
						NSXMLElement *spanElement = [[li children] lastObject];
						
						if ([spanElement childCount] == 0)
							continue;
						
						NSXMLElement *codeElement = [[spanElement children] objectAtIndex:0];
						NSXMLElement *a = [[codeElement children] lastObject];
						
						NSString *href = [[a attributeForLocalName:@"href"] commentlessStringValue];
						NSString *strval = [a commentlessStringValue];
						
						if (!href || !strval)
							continue;
						
						if (!MetaTaskGroupItemEntity)
							MetaTaskGroupItemEntity = [NSEntityDescription entityForName:@"MetaTaskGroupItem" inManagedObjectContext:transientContext];
						
						NSManagedObject *taskgroupItem = [[NSManagedObject alloc] initWithEntity:MetaTaskGroupItemEntity insertIntoManagedObjectContext:transientContext];
						[taskgroupItem setValue:href forKey:@"href"];
						
						//Some bright spark at Apple throught it was a good idea to use an en-dash instead of a hyphen-minus to denote an instance method. This means task items can't be copied from Apple's docs verbatim, as the hyphen won't compile properly.
						strval = [strval stringByReplacingOccurrencesOfString:@"\u2013" withString:@"-"];
						
						[taskgroupItem setValue:[strval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
						[taskgroupItem setValue:[NSNumber numberWithInt:taskgroupItemPositionIndex] forKey:@"positionIndex"];
						[taskgroupItem setValue:taskgroup forKey:@"parentGroup"];
						
						taskgroupItemPositionIndex++;
					}
				}
			}
		}
		
	}
}
- (void)scrapeAbstractMethodContainerNonDeprecatedBits
{
	NSError *err = nil;
	
	[transientObject setValue:[NSSet set] forKey:@"methods"];
	[transientObject setValue:[NSSet set] forKey:@"properties"];
	[transientObject setValue:[NSSet set] forKey:@"notifications"];
	[transientObject setValue:[NSSet set] forKey:@"delegatemethods"];
	[transientObject setValue:[NSSet set] forKey:@"taskgroups"];
	
	//Find <div id="Overview_section" class="zClassDescription">	
	NSArray *overviewSectionNodes = [[doc rootElement] nodesForXPath:@"//div[@id='Overview_section']" error:&err];
	//FIXME: This (faster) version isn't working for some reason. It should be equivalent
	/*
	 NSArray *overviewSectionNodes1 = [[doc rootElement] nodesMatchingPredicate:^BOOL(NSXMLNode *node) {
	 return [[node name] isEqual:@"div"] && [[node attributeForLocalName:@"id"] isEqual:@"Overview_section"];
	 }];
	 */
	for (NSXMLElement *el in overviewSectionNodes)
	{
		if (![el isKindOfClass:[NSXMLElement class]])
			continue;
		
		if (![el childCount])
			continue;
		
		[self scrapeAbstractMethodContainerTopDOMChildren:[el children] index:0 type:0];
		break;
	}
	
	
	//Find <div id="Tasks_section" class="zMethodsByTask">	
	NSArray *tasksSectionNodes = [[doc rootElement] nodesForXPath:@"//div[@id='Tasks_section']" error:&err];
	
	//FIXME: Same deal as above. This (faster) version isn't working for some reason. It should be equivalent
	/*
	 NSArray *tasksSectionNodes1 = [[doc rootElement] nodesMatchingPredicate:^BOOL(NSXMLNode *node) {
	 return [[node name] isEqual:@"div"] && [[node attributeForLocalName:@"id"] isEqual:@"Tasks_section"];
	 }];
	 */
	for (NSXMLElement *el in tasksSectionNodes)
	{
		if (![el isKindOfClass:[NSXMLElement class]])
			continue;
		
		if (![el childCount])
			continue;
		
		[self scrapeAbstractMethodContainerTopDOMChildren:[el children] index:0 type:1];
		break;
	}
	
}
- (void)scrapeAbstractMethodContainer
{	
	if (!isParsingDeprecatedAppendix)
	{
		[self scrapeAbstractMethodContainerNonDeprecatedBits];
	}
	
	// NSArray *methodNodes1 = [[doc rootElement] nodesForXPath:@"//a" error:&err];
	
	//Search through all anchors in the document, and record their parent elements
	NSArray *mnodes = [self methodNodes];
	NSHashTable *containersSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsOpaquePersonality capacity:[mnodes count]];
	for (NSXMLElement *a in mnodes)
	{
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *name = [[a attributeForLocalName:@"name"] commentlessStringValue];
		if (name)
		{
			[containersSet addObject:[a parent]];
		}
	}
	
	//For each container
	NSMutableArray *methods = [[NSMutableArray alloc] init];
	for (NSXMLNode *container in containersSet)
	{
		__block BOOL lastWasProperty = NO;
				
		//Split the container's children array by "interesting" <a> elements
		NSArray *arr = [[self class] splitArray:[container children] byBlock:^ NSString* (id a) {
			if (![a isKindOfClass:[NSXMLElement class]])
				return nil;
			
			NSXMLNode *el = [a attributeForLocalName:@"name"];
			NSString *strval = [el commentlessStringValue];
			//(instm|clm|intfm|intfcm|intfp|instp)
			
			BOOL lastWasPropertyTrue = lastWasProperty;
			lastWasProperty = NO;
			
			if ([strval hasPrefix:@"//apple_ref/occ/intfp"] || [strval hasPrefix:@"//apple_ref/occ/instp"])
			{
				lastWasProperty = YES;
				return @"ObjCProperty";
			}
			
			
			BOOL isInstanceMethod = [strval hasPrefix:@"//apple_ref/occ/instm"] || [strval hasPrefix:@"//apple_ref/occ/intfm"];
			BOOL isClassMethod = [strval hasPrefix:@"//apple_ref/occ/clm"] || [strval hasPrefix:@"//apple_ref/occ/intfcm"];
			if (isInstanceMethod || isClassMethod)
			{
				if (lastWasPropertyTrue)
				{
					lastWasProperty = YES;
					return nil;
				}
				
				if (isInstanceMethod)
					return @"ObjCMethod_Instance";
				return @"ObjCMethod_Class";
			}
			
			if ([strval hasPrefix:@"//apple_ref/c/data"])
				return @"ObjCNotification";
						
			return nil;
		}];
		
		[methods addObjectsFromArray:arr];
	}
	
	for (NSArray *arr in methods)
	{
		if ([arr count] < 2)
			continue;
		
		NSString *entityName = [arr objectAtIndex:0];
				
		int isInstanceMethod = -1;
		if ([entityName isEqual:@"ObjCMethod_Instance"])
		{
			isInstanceMethod = 1;
			entityName = @"ObjCMethod";
		}
		else if ([entityName isEqual:@"ObjCMethod_Class"])
		{
			isInstanceMethod = 0;
			entityName = @"ObjCMethod";
		}
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:transientContext];
		
		IGKDocRecordManagedObject *newItem = [[IGKDocRecordManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:transientContext];
		
		if (isInstanceMethod != -1)
		{
			[newItem setValue:[NSNumber numberWithBool:isInstanceMethod] forKey:@"isInstanceMethod"];
		}
		
		[self scrapeMethodChildren:arr index:0 managedObject:newItem];
		
		//If this is a notification but the name does not end in 'Notification' then it's some other kind of data - ignore it
		//TODO: When we get around to handling C constants this will need to be fixed so it's not just ignored
		if ([entityName isEqual:@"ObjCNotification"] && ![[newItem valueForKey:@"name"] hasSuffix:@"Notification"])
		{
			continue;
		}
		
		[newItem setValue:transientObject forKey:@"container"];
		[newItem setValue:transientObject forKey:@"globalContainer"];
		[newItem setValue:docset forKey:@"docset"];
	}
}

- (void)scrapeBindingsListing
{
	//Search through all anchors in the document, and record their parent elements
	NSArray *mnodes = [self methodNodes];
	NSHashTable *containersSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsOpaquePersonality capacity:[mnodes count]];
	for (NSXMLElement *a in mnodes)
	{
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *name = [[a attributeForLocalName:@"name"] commentlessStringValue];
		if (name)
		{
			[containersSet addObject:[a parent]];
		}
	}
	
	//Partition into bindings descriptions
	NSMutableArray *methods = [[NSMutableArray alloc] init];
	for (NSXMLNode *container in containersSet)
	{		
		//Split the container's children array by "interesting" <a> elements
		NSArray *arr = [[self class] splitArray:[container children] byBlock:^ NSString* (id a) {
			if (![a isKindOfClass:[NSXMLElement class]])
				return nil;
			
			NSXMLNode *el = [a attributeForLocalName:@"name"];
			NSString *strval = [el commentlessStringValue];
			
			if ([strval hasPrefix:@"//apple_ref/occ/binding"])
			{
				return @"ObjCBinding";
			}
			
			return nil;
		}];
		
		[methods addObjectsFromArray:arr];
	}
	
	//Scrape each partition
	for (NSArray *arr in methods)
	{
		if ([arr count] < 2)
			continue;
				
		if (!ObjCBindingEntity)
			ObjCBindingEntity = [NSEntityDescription entityForName:@"ObjCBinding" inManagedObjectContext:transientContext];
		
		IGKDocRecordManagedObject *newItem = [[IGKDocRecordManagedObject alloc] initWithEntity:ObjCBindingEntity insertIntoManagedObjectContext:transientContext];
		
		[self scrapeBinding:arr index:0 managedObject:newItem];
		
		[newItem setValue:transientObject forKey:@"container"];
	}	
}
- (void)scrapeBinding:(NSArray *)children index:(NSUInteger)index managedObject:(NSManagedObject *)object
{
	BOOL hasRecordedBindingsListing = NO;
	
	NSUInteger i = 0;
	NSUInteger count = [children count];
	
	BOOL isOnlyAElements = YES;
	if (count == 0)
		isOnlyAElements = NO;
	
	for (i = index; i < count; i++)
	{
		NSXMLElement *n = [children objectAtIndex:i];
		if (![n isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *nName = [[n name] lowercaseString];
		NSArray *nClass = [[[[n attributeForLocalName:@"class"] commentlessStringValue] lowercaseString] componentsSeparatedByString:@" "];
		
		if (![nName isEqual:@"a"])
			isOnlyAElements = NO;
		
		//name
		// <h3 class="*jump*"> ... </h3>
		if ([nName isEqual:@"h3"] && [nClass containsObject:@"jump"])
		{
			//If we've already recorded a method, then we're done
			if (hasRecordedBindingsListing)
				break;
			hasRecordedBindingsListing = YES;
			[object setValue:[[n commentlessStringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
			
			continue;
		}
		
		//overview
		/* <p> ... </p> <p> ... </p> <p> ... </p> ... */
		if ([nName isEqual:@"p"])
		{
			NSMutableString *description = [[NSMutableString alloc] init];
			
			NSUInteger j;
			for (; i < count; i++)
			{
				NSXMLElement *m = [children objectAtIndex:i];
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				
				NSString *mLowerName = [[m name] lowercaseString];
				if (![mLowerName isEqual:@"p"])
				{
					i--;
					break;
				}
				
				[description appendFormat:@"<p>%@</p>", [m commentlessStringValue]];
			}
			
			[object setValue:description forKey:@"overview"];
		}
		
		//availability
		/* <div class="availabilityList">
		     <strong>Availability:</strong>
		     <div class="availabilityItem">Available in Mac OS X v10.3 and later.</div>
		   </div>
		 */
		if ([nName isEqual:@"div"] && [nClass containsObject:@"availabilityList"])
		{
			NSArray *nChildren = [n children];
			for (NSXMLNode *m in nChildren)
			{
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				
				if (![[[m name] lowercaseString] isEqual:@"div"])
					continue;
				
				[object setValue:[m commentlessStringValue] forKey:@"availability"];
			}
		}
		
		//isReadOnly
		// <strong>Binding is Read-Only.</strong>
		if ([nName isEqual:@"strong"])
		{
			if ([[n commentlessStringValue] hasPrefix:@"Binding is Read-Only"])
			{
				[object setValue:[NSNumber numberWithBool:YES] forKey:@"isReadOnly"];
			}
		}
		
		
		//placeholders
		/* <div class="placeholder_options_block">
		     <span class="bindings_tablehead">Binding Options</span>
		     <table class="graybox" border="0" cellspacing="0" cellpadding="5">
		       <tr valign="top">
		         <td scope="row">
				   <span class="content_text">Raises for Not Applicable Keys</span>
				 </td>
				 <td>
				   <tt>...</tt>
				 </td>
				 <td>
				   <span class="content_text">NSNumber (Boolean)</span>
			     </td>
			   </tr>
			 </table>
		   </div>
		*/
		void (^parseOptionsTable)(NSManagedObject *, NSArray *) = ^(NSManagedObject *bindingsObject, NSArray *parentChildren) {
		
			if ([parentChildren count])
			{		
				BOOL isPlaceholders = NO;
				
				for (NSXMLNode *m in parentChildren)
				{
					if (![m isKindOfClass:[NSXMLElement class]])
						continue;
										
					//Find out what kind of objects we will be creating
					if ([[[m name] lowercaseString] isEqual:@"span"])
					{
						NSString *mStringValue = [m commentlessStringValue];
						if ([mStringValue isEqual:@"Binding Options"])
							isPlaceholders = NO;
						else if ([mStringValue isEqual:@"Placeholders"])
							isPlaceholders = YES;
						
						continue;
					}
					
					if ([[[m name] lowercaseString] isEqual:@"table"])
					{
						NSArray *rows = [m children];
						for (NSXMLNode *row in rows)
						{
							if (![row isKindOfClass:[NSXMLElement class]])
								continue;
							
							NSManagedObject *subobject = nil;
							for (NSXMLNode *cell in [row children])
							{
								if (![cell isKindOfClass:[NSXMLElement class]])
									continue;
								
								//If this is a row full of header cells, continue on to the next row
								if (![[[cell name] lowercaseString] isEqual:@"td"])
									continue;
								
								//This is a data row so create a new managed object
								if (!subobject)
								{
									if (isPlaceholders)
									{
										if (!ObjCBindingPlaceholderEntity)
											ObjCBindingPlaceholderEntity = [NSEntityDescription entityForName:@"ObjCBindingPlaceholder" inManagedObjectContext:transientContext];
										subobject = [[NSManagedObject alloc] initWithEntity:ObjCBindingPlaceholderEntity insertIntoManagedObjectContext:transientContext];
										
										
									}
									else
									{
										if (!ObjCBindingOptionEntity)
											ObjCBindingOptionEntity = [NSEntityDescription entityForName:@"ObjCBindingOption" inManagedObjectContext:transientContext];
										subobject = [[NSManagedObject alloc] initWithEntity:ObjCBindingOptionEntity insertIntoManagedObjectContext:transientContext];
										
									}
								}
								
								//Try to set the option's name
								if ([[[[(NSXMLElement *)cell attributeForLocalName:@"scope"] commentlessStringValue] lowercaseString] isEqual:@"row"])
								{
									NSString *placeholderConstant = [cell commentlessStringValue];
									if (placeholderConstant)
										[subobject setValue:placeholderConstant forKey:@"option"];
									continue;
								}
								
								//Try to set the option's type
								NSArray *cellChildren = [cell children];
								if ([cellChildren count])
								{
									NSXMLNode *possibleTTNode = [cellChildren objectAtIndex:0];
									if ([[[possibleTTNode name] lowercaseString] isEqual:@"tt"])
									{
										[subobject setValue:[possibleTTNode commentlessStringValue] forKey:@"placeholderConstant"];
										continue;
									}
								}
								
								//Otherwise set the option's class
								NSString *cellStringValue = [cell commentlessStringValue];
								if (cellStringValue)
								{
									[subobject setValue:cellStringValue forKey:@"valueClass"];
									continue;
								}
							}
							
							[subobject setValue:object forKey:@"binding"];
						}
					}
				}
			}
		};
		
		if ([nClass containsObject:@"placeholder_options_block"])
        {
			parseOptionsTable(object, [n children]);
		}
	}
}

+ (NSArray *)splitArray:(NSArray *)array byBlock:(NSString* (^)(id a))block
{
	NSMutableArray *arrays = [[NSMutableArray alloc] init];
	
	NSMutableArray *currentArray = nil;
	
	for (id a in array)
	{		
		NSString *entityName = nil;
		if (entityName = block(a))
		{			
			currentArray = [[NSMutableArray alloc] init];
			[arrays addObject:currentArray];

			[currentArray addObject:entityName];
		}
		else
		{
			[currentArray addObject:a];
		}
	}
	
	return arrays;
}
+ (NSArray *)array:(NSArray *)array findObjectByBlock:(BOOL (^)(id a))block
{	
	for (id a in array)
	{
		if (block(a))
		{
			return a;
		}
	}
	
	return nil;
}

- (void)createMethodNamed:(NSString *)name description:(NSString *)description prototype:(NSString *)prototype
			 methodEntity:(NSEntityDescription *)methodEntity parent:(NSManagedObject*)parent docset:(NSManagedObject*)theDocset
{
	if (name == nil)
		return;
		
	IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:methodEntity insertIntoManagedObjectContext:transientContext];
	
	[newMethod setValue:[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"name"];
	
	if ([description length])
		[newMethod setValue:description forKey:@"overview"];
	
	[newMethod setValue:prototype forKey:@"signature"];
	
	[newMethod setValue:parent forKey:@"container"];
	[newMethod setValue:parent forKey:@"globalContainer"];
	[newMethod setValue:theDocset forKey:@"docset"];
}


@end
