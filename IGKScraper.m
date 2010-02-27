//
//  IGKScraper.m
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKScraper.h"
#import "RegexKitLite.h"
#import "IGKDocRecordManagedObject.h"
#import "IGKLaunchController.h"


@interface IGKScraper ()

- (NSUInteger)backgroundSearch:(NSManagedObject *)docset;

- (BOOL)extractPath:(NSString *)extractPath docset:(NSManagedObject *)docset;
- (NSManagedObject *)addRecordNamed:(NSString *)recordName entityName:(NSString *)entityName desc:(NSString *)recordDesc sourcePath:(NSString *)recordPath;

@end

@implementation IGKScraper

- (id)initWithDocsetURL:(NSURL *)theDocsetURL managedObjectContext:(NSManagedObjectContext *)moc launchController:(IGKLaunchController*)lc dbQueue:(dispatch_queue_t)dbq
{
	if (self = [super init])
	{
		docsetURL = [theDocsetURL copy];
		url = [docsetURL URLByAppendingPathComponent:@"Contents/Resources/Documents/documentation"];
		ctx = moc;
		
		launchController = lc;
		dbQueue = dbq;
	}
	
	return self;
}

- (BOOL)findPaths
{
	//Get the info.plist
	NSDictionary *infoPlist = [[NSDictionary alloc] initWithContentsOfURL:[docsetURL URLByAppendingPathComponent:@"Contents/Info.plist"]];
	NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
	
	//Reject Xcode documentation
	if (!bundleIdentifier || [bundleIdentifier isEqual:@"com.apple.adc.documentation.AppleXcode.DeveloperTools"])
		return NO;
	
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
	if ([infoPlist objectForKey:@"DocSetPlatformVersion"])
		[docset setValue:[infoPlist objectForKey:@"DocSetPlatformVersion"] forKey:@"platformVersion"];
	if ([infoPlist objectForKey:@"DocSetFallbackURL"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFallbackURL"] forKey:@"fallbackURL"];
	
	[docset setValue:[docsetURL absoluteString] forKey:@"url"];
	
	
	scraperDocset = docset;
	paths = [[NSMutableArray alloc] init];
	//pathsCount = [self backgroundSearch:docset];
	
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
			[subpath isLike:@"*RefUpdate/*"])
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
		
		[paths addObject:[urlpath stringByAppendingPathComponent:subpath]];
	}
	
	return [paths count];
}
- (void)index
{
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		for (NSString *extractPath in paths)
		{
			[self extractPath:extractPath docset:scraperDocset];
			pathsCounter += 1;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[launchController reportPath];
			});
		}
	});
}

- (BOOL)extractPath:(NSString *)extractPath docset:(NSManagedObject *)docset
{	
	//Let's try to extract the class's name (assuming it is a class of course)	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:extractPath encoding:NSUTF8StringEncoding error:&error];
	if (error || !contents)
	{
		return NO;
	}
	
	
	//Parse the item's name and kind
	NSString *regex_className = @"<a name=\"//apple_ref/(occ/([a-z_]+)/([a-zA-Z_][a-zA-Z0-9_]*)|c/([a-zA-Z_][a-zA-Z0-9_]*))";
	NSArray *className_captures = [contents captureComponentsMatchedByRegex:regex_className];
	if ([className_captures count] < 3)
	{
		return NO;
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
	else
	{
		// bail
		return NO;
	}
	
	//Superclass
	NSString *superclass = nil;
	if (parentItemType == ParentItemType_ObjCClass)
	{
		//Find the superclass
		NSString *superclassRegex = @"Inherits from.+?>([A-Za-z0-9_$]+)<";
		
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
				conformsTo = [[NSMutableSet alloc] init];
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
	
	//Declared in
	NSString *declaredInRegex = @"Declared in.+?<span class=\"content_text\">([^<]+)<";
	
	
	NSString *linkRegex = @"name=\"//apple_ref/((occ/(instm|clm|intfm|intfcm|intfp|instp)/[a-zA-Z_:][a-zA-Z0-9:_]*/([a-zA-Z:_][a-zA-Z0-9:_]*))|(c/([a-zA-Z0-9_]+)/([a-zA-Z:_][a-zA-Z0-9:_]*)))\"([^<>]+role=\"([a-zA-Z0-9_]+)\")?";
	
	/* The interesting captures are 3 & 4, and 5 & 6 */
	NSArray *items = [contents arrayOfCaptureComponentsMatchedByRegex:linkRegex];
	
	
	dispatch_sync(dbQueue, ^{
		
		NSEntityDescription *propertyEntity = [NSEntityDescription entityForName:@"ObjCProperty" inManagedObjectContext:ctx];
		NSEntityDescription *methodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:ctx];
		
		NSEntityDescription *globalVariableEntity = nil;
		NSEntityDescription *constantEntity = nil;
		NSEntityDescription *functionEntity = nil;
		NSEntityDescription *macroEntity = nil;
		NSEntityDescription *typedefEntity = nil;
		NSEntityDescription *enumEntity = nil;
		NSEntityDescription *structEntity = nil;
		NSEntityDescription *unionEntity = nil;
		NSEntityDescription *cppMethodEntity = nil;
		NSEntityDescription *cppClassStructEntity = nil;
		NSEntityDescription *cppNamespaceEntity = nil;
		
		NSManagedObject *obj = nil;
		if (entityName)
		{
			obj = [self addRecordNamed:name entityName:entityName desc:@"" sourcePath:extractPath];
			[obj setValue:docset forKey:@"docset"];
			
			if ([superclass length])
				[obj setValue:superclass forKey:@"superclass"];
			if ([conformsTo count])
				[obj setValue:[[conformsTo allObjects] componentsJoinedByString:@","] forKey:@"conformsto"];
		}
		
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
					
					IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:isProperty ? propertyEntity : methodEntity insertIntoManagedObjectContext:ctx];
					
					[newMethod setValue:itemName forKey:@"name"];
					[newMethod setValue:obj forKey:@"container"];
					[newMethod setValue:docset forKey:@"docset"];
					[newMethod setValue:extractPath forKey:@"documentPath"];
					
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
						if (!constantEntity)
							constantEntity = [NSEntityDescription entityForName:@"CConstant" inManagedObjectContext:ctx];
						
						newSubobject = [[IGKDocRecordManagedObject alloc] initWithEntity:constantEntity insertIntoManagedObjectContext:ctx];
					}
					
					if (newSubobject)
					{
						[newSubobject setValue:itemName forKey:@"name"];
						[newSubobject setValue:docset forKey:@"docset"];
						[newSubobject setValue:extractPath forKey:@"documentPath"];
					}

					
					continue;
				}
			}
		}
	
	});
		
	return YES;
}

- (NSManagedObject *)addRecordNamed:(NSString *)recordName entityName:(NSString *)entityName desc:(NSString *)recordDesc sourcePath:(NSString *)recordPath
{
	NSEntityDescription *ed = [NSEntityDescription entityForName:entityName inManagedObjectContext:ctx];
	
	NSManagedObject *newRecord = [[IGKDocRecordManagedObject alloc] initWithEntity:ed insertIntoManagedObjectContext:ctx];
	
	[newRecord setValue:recordName forKey:@"name"];
	[newRecord setValue:recordDesc forKey:@"overview"];
	[newRecord setValue:recordPath forKey:@"documentPath"];
	
	return newRecord;
}


@end


@interface IGKFullScraper ()

+ (NSArray *)splitArray:(NSArray *)array byBlock:(BOOL (^)(id a))block;
+ (NSArray *)array:(NSArray *)array findObjectByBlock:(BOOL (^)(id a))block;

- (void)createMethodNamed:(NSString *)name description:(NSString *)description prototype:(NSString *)prototype methodEntity:(NSEntityDescription *)methodEntity parent:(NSManagedObject*)parent docset:(NSManagedObject*)docset transientContext:(NSManagedObjectContext *)transientContext;

- (void)scrape;
- (void)scrapeAbstractMethodContainer;

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
	//Get persistobj's equivalent in transientContext
	transientObject = (IGKDocRecordManagedObject *)[transientContext objectWithID:[persistobj objectID]];
	
	docset = [transientObject valueForKey:@"docset"];
	NSString *extractPath = [transientObject valueForKey:@"documentPath"];
	
	NSURL *fileurl = [NSURL fileURLWithPath:extractPath];
	
	NSError *err = nil;
	doc = [[NSXMLDocument alloc] initWithContentsOfURL:fileurl options:NSXMLDocumentTidyHTML error:&err];
	if (!doc)
		return;
	
	//Depending on the type of obj, we will need to parse it differently
	if ([[transientObject entity] isKindOfEntity:[NSEntityDescription entityForName:@"ObjCAbstractMethodContainer" inManagedObjectContext:transientContext]])
	{
		[self scrapeAbstractMethodContainer];
	}
	else if ([[transientObject entity] isKindOfEntity:[NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:transientContext]])
	{
		[self scrapeMethod];
		//[self extractFully_ObjCAbstractMethodContainer:];
	}
}

- (void)scrapeMethod
{
	NSError *err = nil;
	NSArray *methodNodes = [[doc rootElement] nodesForXPath:@"//a" error:&err];
	
	//Search through all anchors in the document, and record their parent elements
	NSMutableSet *containersSet = [[NSMutableSet alloc] init];
	for (NSXMLElement *a in methodNodes)
	{
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *name = [[a attributeForName:@"name"] stringValue];
		
		NSXMLNode *el = [a attributeForName:@"name"];
		NSString *strval = [el stringValue];
		//(instm|clm|intfm|intfcm|intfp|instp)
		if ([strval isLike:@"//apple_ref/occ/instm*"] || [strval isLike:@"//apple_ref/occ/clm*"] ||
			[strval isLike:@"//apple_ref/occ/intfm*"] || [strval isLike:@"//apple_ref/occ/intfcm*"] ||
			[strval isLike:@"//apple_ref/occ/intfp*"] || [strval isLike:@"//apple_ref/occ/instp*"])
		{
			NSString *methodName = [transientObject valueForKey:@"name"];
			
			//This is a bit ropey
			if ([strval isLike:[@"*" stringByAppendingString:methodName]])
			{
				NSArray *children = [[a parent] children];
				NSInteger index = [children indexOfObject:a];
				if (index != -1)
					[self scrapeMethodChildren:children index:index managedObject:transientObject];
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
	for (i = index; i < count; i++)
	{
		NSXMLElement *n = [children objectAtIndex:i];
		if (![n isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *nName = [[n name] lowercaseString];
		NSArray *nClass = [[[[n attributeForName:@"class"] stringValue] lowercaseString] componentsSeparatedByString:@" "];
		
		//name
		// <h3 class="*jump*"> ... </h3>
		if ([nName isEqual:@"h3"] && [nClass containsObject:@"jump"])
		{
			//If we've already recorded a method, then we're done
			if (hasRecordedMethod)
				break;
			hasRecordedMethod = YES;
			
			[object setValue:[n stringValue] forKey:@"name"];
			continue;
		}
		
		//overview
		// <p class="spaceabove"> ... </p> <p class="spaceabove"> ... </p> ...
		if ([nClass containsObject:@"spaceabove"])
		{
			NSMutableString *overview = [[NSMutableString alloc] init];
			[overview appendFormat:@"<p>%@</p>", [n stringValue]];
			
			NSUInteger j;
			for (j = i + 1; j < count; j++)
			{
				NSXMLElement *m = [children objectAtIndex:j];
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				if (![[[m attributeForName:@"class"] stringValue] isEqual:@"spaceabove"])
					break;
				
				[overview appendFormat:@"<p>%@</p>", [m stringValue]];
			}
			
			[object setValue:overview forKey:@"overview"];
			continue;
		}
		
		//prototype
		// <p class="spaceabovemethod"> ... </p>
		if ([nClass containsObject:@"spaceabovemethod"])
		{
			NSMutableString *prototype = [[NSMutableString alloc] init];
			[prototype appendString:[n stringValue]];
			
			[object setValue:prototype forKey:@"signature"];
			continue;
		}
		
		//parameters
		/* <dl class="termdef">
		       <dt> ... name ... </dt>
		       <dd> ... overview ... </dd>
		   </dl>
		 */
		if ([nName isEqual:@"dl"] && [nClass containsObject:@"termdef"])
		{
			NSArray *nChildren = [n children];
			NSString *lastDT = nil;
			for (NSXMLElement *m in nChildren)
			{
				if ([[[m name] lowercaseString] isEqual:@"dt"])
				{
					lastDT = [m stringValue];
				}
				else if ([lastDT length] && [[[m name] lowercaseString] isEqual:@"dd"])
				{
					NSString *dd = [m stringValue];
					
					if ([dd length])
					{
						if (!ParameterEntity)
							ParameterEntity = [NSEntityDescription entityForName:@"Parameter" inManagedObjectContext:transientContext];
						
						NSManagedObject *parameter = [[NSManagedObject alloc] initWithEntity:ParameterEntity insertIntoManagedObjectContext:transientContext];
						[parameter setValue:lastDT forKey:@"name"];
						[parameter setValue:dd forKey:@"overview"];
						[parameter setValue:object forKey:@"callable"];
					}
					
					lastDT = nil;
				}
			}
			
			continue;
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
				
				[returnValueDescription appendString:[m stringValue]];
			}
			
			[object setValue:returnValueDescription forKey:@"returnDescription"];
			continue;
		}
		
		//discussion
		/* <h5 class="tight">Discussion</h5>
		   <p> ... </p>
		   <p> ... </p>
		   ...
		 */
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isEqual:@"discussion"])
		{
			NSMutableString *discussion = [[NSMutableString alloc] init];
			
			NSUInteger j;
			for (j = i + 1; j < count; j++)
			{
				NSXMLElement *m = [children objectAtIndex:j];
				if (![m isKindOfClass:[NSXMLElement class]])
					continue;
				if (![[[m name] lowercaseString] isEqual:@"p"])
					break;
				
				[discussion appendFormat:@"<p>%@</p>", [m stringValue]];
			}
			
			[object setValue:discussion forKey:@"discussion"];
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
						[object setValue:[ulChild stringValue] forKey:@"availability"];
						
						break;
					}
					
					continue;
				}
			}
		}
		
		//seealsos
		/* <h5 class="tight">See Also</h5>
		   <ul class="availability">
			   <li class="availability">
				   <code>
					   <a href=" ... ">&#8211;&#xA0; ... </a>
				   </code>
			   </li>
		   </ul>
		 */
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isEqual:@"see also"])
		{			
			NSXMLElement *ul = [children objectAtIndex:i + 1];
			if ([[[ul name] lowercaseString] isEqual:@"ul"])
			{				
				for (NSXMLElement *li in [ul children])
				{					
					NSXMLElement *codeElement = [[li children] lastObject];
					NSXMLElement *a = [[codeElement children] lastObject];
					
					NSString *href = [[a attributeForName:@"href"] stringValue];
					NSString *strval = [a stringValue];
					
					if (!href || !strval)
						continue;
					
					if (!SeeAlsoEntity)
						SeeAlsoEntity = [NSEntityDescription entityForName:@"SeeAlso" inManagedObjectContext:transientContext];
					
					NSManagedObject *seealso = [[NSManagedObject alloc] initWithEntity:SeeAlsoEntity insertIntoManagedObjectContext:transientContext];
					[seealso setValue:href forKey:@"href"];
					[seealso setValue:strval forKey:@"name"];
					[seealso setValue:object forKey:@"container"];
				}
			}
		}
		
		//samplecodeprojects
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
		if (i + 1 < count && [nName isEqual:@"h5"] && [[[[n stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] isLike:@"*sample code*"])
		{			
			NSXMLElement *ul = [children objectAtIndex:i + 1];
			if ([[[ul name] lowercaseString] isEqual:@"ul"])
			{				
				for (NSXMLElement *li in [ul children])
				{					
					NSXMLElement *spanElement = [[li children] lastObject];
					NSXMLElement *a = [[spanElement children] lastObject];
					
					NSString *href = [[a attributeForName:@"href"] stringValue];
					NSString *strval = [a stringValue];
					
					if (!href || !strval)
						continue;
					
					if (!SampleCodeProjectEntity)
						SampleCodeProjectEntity = [NSEntityDescription entityForName:@"SampleCodeProject" inManagedObjectContext:transientContext];
					
					NSManagedObject *seealso = [[NSManagedObject alloc] initWithEntity:SampleCodeProjectEntity insertIntoManagedObjectContext:transientContext];
					[seealso setValue:href forKey:@"href"];
					[seealso setValue:strval forKey:@"name"];
					[seealso setValue:object forKey:@"container"];
				}
			}
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
				
				[object setValue:[m stringValue] forKey:@"declared_in_header"];
				break;
			}
			
			continue;
		}
	}
}
- (void)scrapeAbstractMethodContainer
{
	[transientObject setValue:[NSSet set] forKey:@"methods"];
		
	NSError *err = nil;
	NSArray *methodNodes = [[doc rootElement] nodesForXPath:@"//a" error:&err];
	
	
	//Search through all anchors in the document, and record their parent elements
	NSMutableSet *containersSet = [[NSMutableSet alloc] init];
	for (NSXMLElement *a in methodNodes)
	{
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *name = [[a attributeForName:@"name"] stringValue];
		if (name)
		{
			[containersSet addObject:[a parent]];
		}
		
	}
	
	
	//For each container
	NSMutableArray *methods = [[NSMutableArray alloc] init];
	for (NSXMLNode *container in containersSet)
	{
		//Split the container's children array by "interesting" <a> elements
		NSArray *arr = [[self class] splitArray:[container children] byBlock:^BOOL(id a) {
			if (![a isKindOfClass:[NSXMLElement class]])
				return NO;
			
			NSXMLNode *el = [a attributeForName:@"name"];
			NSString *strval = [el stringValue];
			//(instm|clm|intfm|intfcm|intfp|instp)
			if ([strval isLike:@"//apple_ref/occ/instm*"] || [strval isLike:@"//apple_ref/occ/clm*"] ||
				[strval isLike:@"//apple_ref/occ/intfm*"] || [strval isLike:@"//apple_ref/occ/intfcm*"] ||
				[strval isLike:@"//apple_ref/occ/intfp*"] || [strval isLike:@"//apple_ref/occ/instp*"])
				//[strval isLike:@"*/c/func*"] || [strval isLike:@"*/c/tdef*"] || [strval isLike:@"*/c/macro*"])
				return YES;
			return NO;
		}];
		
		[methods addObjectsFromArray:arr];
	}
	
	for (NSArray *arr in methods)
	{
		if (!ObjCMethodEntity)
			ObjCMethodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:transientContext];
	
		IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:ObjCMethodEntity insertIntoManagedObjectContext:transientContext];
		
		[self scrapeMethodChildren:arr index:0 managedObject:newMethod];
		[newMethod setValue:transientObject forKey:@"container"];
		[newMethod setValue:docset forKey:@"docset"];
	}
}

+ (NSArray *)splitArray:(NSArray *)array byBlock:(BOOL (^)(id a))block
{
	NSMutableArray *arrays = [[NSMutableArray alloc] init];
	
	NSMutableArray *currentArray = [[NSMutableArray alloc] init];
	[arrays addObject:currentArray];
	
	for (id a in array)
	{
		if (block(a))
		{
			currentArray = [[NSMutableArray alloc] init];
			[arrays addObject:currentArray];
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
	
	//NSLog(@"name / proto = %@ -- %@", name, prototype);
	
	IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:methodEntity insertIntoManagedObjectContext:transientContext];
	
	[newMethod setValue:name forKey:@"name"];
	
	if ([description length])
		[newMethod setValue:description forKey:@"overview"];
	
	[newMethod setValue:prototype forKey:@"signature"];
	
	[newMethod setValue:parent forKey:@"container"];
	[newMethod setValue:theDocset forKey:@"docset"];
}


@end


































#pragma mark Trash
//Some code I'm saving in case I need it later

#if 0

#pragma mark -- Boyers-Moore

//Surprisingly, -[NSString isLike:] is the bottleneck. We make our own.


//Oh look - some code from wikipedia. I hope it works

const unichar * IGKStringToChars(NSString *string)
{
	unichar *chars = (unichar *)malloc([string length] * sizeof(unichar));
	
	return chars;
}
const unichar * IGKStringToCharsWithLength(NSString *string, size_t length)
{
	unichar *chars = (unichar *)malloc(length * sizeof(unichar));
	
	return chars;
}
BOOL IGKStringIsLike(const unichar *needle, size_t nlen, const unichar *haystack, size_t hlen)
{
    size_t scan = 0;
    size_t bad_char_skip[USHRT_MAX + 1]; /* Officially called:
                                          * bad character shift */
	
    /* Sanity checks on the parameters */
    if (nlen <= 0 || !haystack || !needle)
        return NO;
	
    /* ---- Preprocess ---- */
    /* Initialize the table to default value */
    /* When a character is encountered that does not occur
     * in the needle, we can safely skip ahead for the whole
     * length of the needle.
     */
    for (scan = 0; scan <= USHRT_MAX; scan = scan + 1)
        bad_char_skip[scan] = nlen;
	
    /* C arrays have the first byte at [0], therefore:
     * [nlen - 1] is the last byte of the array. */
    size_t last = nlen - 1;
	
    /* Then populate it with the analysis of the needle */
    for (scan = 0; scan < last; scan = scan + 1)
        bad_char_skip[needle[scan]] = last - scan;
	
    /* ---- Do the matching ---- */
	
    /* Search the haystack, while the needle can still be within it. */
    while (hlen >= nlen)
    {
        /* scan from the end of the needle */
        for (scan = last; haystack[scan] == needle[scan]; scan = scan - 1)
            if (scan == 0) /* If the first byte matches, we've found it. */
                return YES;
		
        /* otherwise, we need to skip some bytes and start again. 
		 Note that here we are getting the skip value based on the last byte
		 of needle, no matter where we didn't match. So if needle is: "abcd"
		 then we are skipping based on 'd' and that value will be 4, and
		 for "abcdd" we again skip on 'd' but the value will be only 1.
		 The alternative of pretending that the mismatched character was 
		 the last character is slower in the normal case (Eg. finding 
		 "abcd" in "...azcd..." gives 4 by using 'd' but only 
		 4-2==2 using 'z'. */
        hlen     -= bad_char_skip[haystack[last]];
        haystack += bad_char_skip[haystack[last]];
    }
	
    return NO;
}
void IGKFreeStringChars(const unichar *string)
{
	free((void *)string);
}



#pragma mark -- NSXMLDocument Indexing

- (void)extractPath:(NSString *)extractPath docset:(NSManagedObject *)docset
{
	NSURL *fileurl = [NSURL fileURLWithPath:extractPath];
	
	NSError *err = nil;
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:fileurl options:NSXMLDocumentTidyHTML error:&err];
	if (!doc)
		return;
	
	NSEntityDescription *methodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:ctx];
	
	NSArray *methodNodes = [[doc rootElement] nodesForXPath:@"//a" error:&err];
	
#if 0
	const unichar *instm_c = IGKStringToChars(@"instm");
	const unichar *clm_c = IGKStringToChars(@"clm");
	const unichar *func_c = IGKStringToChars(@"/c/func");
	const unichar *tdef_c = IGKStringToChars(@"/c/tdef");
	const unichar *macro_c = IGKStringToChars(@"/c/macro");
#endif
	
	NSSet *containersSet = [[NSMutableSet alloc] init];
	for (NSXMLNode *a in methodNodes)
	{
		if (![a isKindOfClass:[NSXMLElement class]])
			continue;
		
		NSString *name = [[a attributeForName:@"name"] stringValue];
		if (name)
		{
#if 0
			size_t namelen = [name length];
			const unichar *namechars = IGKStringToCharsWithLength(name, namelen);
			
			
			//if (![name isLike:@"*instm*"] && ![name isLike:@"*clm*"] && ![name isLike:@"*/c/func*"] && ![name isLike:@"*/c/tdef*"]  && ![name isLike:@"*/c/macro*"])
			if (IGKStringIsLike(instm_c, 5, namechars, namelen) ||
				IGKStringIsLike(clm_c, 3, namechars, namelen) ||
				IGKStringIsLike(func_c, 7, namechars, namelen) ||
				IGKStringIsLike(tdef_c, 7, namechars, namelen) ||
				IGKStringIsLike(macro_c, 8, namechars, namelen)) //Yeah entering lengths like this is really error prone
			{
				
			}
			
			IGKFreeStringChars(namechars);
#endif
			[containersSet addObject:[a parent]];
		}
		
	}
	
#if 0
	IGKFreeStringChars(instm_c);
	IGKFreeStringChars(clm_c);
	IGKFreeStringChars(func_c);
	IGKFreeStringChars(tdef_c);
	IGKFreeStringChars(macro_c);
#endif
	
	
	NSMutableArray *methods = [[NSMutableArray alloc] init];
	for (NSXMLNode *container in containersSet)
	{
		NSArray *arr = [self splitArray:[container children] byBlock:^BOOL(id a) {
			if (![a isKindOfClass:[NSXMLElement class]])
				return NO;
			
			NSXMLNode *el = [a attributeForName:@"name"];
			if ([[el stringValue] isLike:@"*instm*"])
				return YES;
			return NO;
		}];
		
		[methods addObjectsFromArray:arr];
	}
		
	dispatch_async(dbQueue, ^{
		
		//More parsing, database stuff
		
		//NSManagedObject *obj = [self addRecordNamed:name entityName:entityName desc:abstract sourcePath:extractPath];
		
		for (NSArray *arr in methods)
		{
			NSString *name = nil;
			NSMutableString *description = nil;
			NSString *prototype = nil;
			
			for (NSXMLElement *n in arr)
			{
				if (![n isKindOfClass:[NSXMLElement class]])
					continue;
				
				if ([[n name] isEqual:@"h3"])
				{
					[self createMethodNamed:name description:description prototype:prototype methodEntity:methodEntity parent:nil docset:docset];
					
					description = [[NSMutableString alloc] init];
					prototype = nil;
					name = [n stringValue];
					continue;
				}
				
				if ([[n name] isEqual:@"p"])
				{
					if ([[[n attributeForName:@"class"] stringValue] isEqual:@"spaceabovemethod"])
					{
						prototype = [n stringValue];
					}
					else
					{
						[description appendFormat:@"<p>%@</p>", [n stringValue]];
					}
				}
			}
			
			[self createMethodNamed:name description:description prototype:prototype methodEntity:methodEntity parent:nil docset:docset];
		}
		
	});
	
	return;
	
	//Let's try to extract the class's name (assuming it is a class of course)	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:extractPath encoding:NSUTF8StringEncoding error:&error];
	if (error || !contents)
		return NO;
	
	
	//Parse the item's name and kind
	NSString *regex_className = @"<a name=\"//apple_ref/occ/([a-z_]+)/([a-zA-Z_][a-zA-Z0-9_]*)";
	NSArray *className_captures = [contents captureComponentsMatchedByRegex:regex_className];
	if ([className_captures count] < 3)
		return NO;
	
	NSString *type = [className_captures objectAtIndex:1];
	NSString *name = [className_captures objectAtIndex:2];
	
	/* Common types
	 cl		- class
	 intf	- protocol
	 instm	- old/deprecated classes
	 intfm	- old/deprecated protocols
	 cat		- category
	 binding - bindings listing
	 */
	
	NSString *entityName = nil;
	if ([type isEqual:@"cl"] || [type isEqual:@"instm"])
		entityName = @"ObjCClass";
		
		else if ([type isEqual:@"cat"])
			entityName = @"ObjCCategory";
			
			else if ([type isEqual:@"intf"] || [type isEqual:@"intfm"])
				entityName = @"ObjCProtocol";
				
				else if ([type isEqual:@"binding"])
					entityName = @"ObjCBindingsListing";
					
					//If we don't understand the entity name, bail
					if (!entityName)
						return NO;
	
	//Parse the abstract
	NSString *regex_abstract = @"<a name=\"[^\"]+\" title=\"Overview\"></a>[ \\t\\n]*<h2[^>]+>Overview</h2>(.+?)((<a name=\"[^\"]+\" title=\"[^\"]+\"></a>[ \\t\\n]*<h2 class=\"jump\">)|(<div id=\"pageNavigationLinks\"))"; //@"<div [^>]*id=\"Overview_section\"[^>]*>(.+)</div>\\s*<a name=";
	NSArray *abstract_captures = [contents captureComponentsMatchedByRegex:regex_abstract
																   options:(RKLDotAll|RKLCaseless)
																	 range:NSMakeRange(0, [contents length])
																	 error:nil];
	NSString *abstract = nil;
	if ([abstract_captures count] >= 2)
		abstract = [abstract_captures objectAtIndex:1];
		
		//Deprecation appendicies and bindings listings have no abstract	
		if ([abstract length] == 0)
		{
			abstract = @"";
		}
	
	NSManagedObject *obj = [self addRecordNamed:name entityName:entityName desc:abstract sourcePath:extractPath];
	[obj setValue:docset forKey:@"docset"];
	
	NSString *regex_instanceMethodBlock = @"<h2 class=\"jump\">\\s*Instance Methods\\s*</h2>(.+?)(<h2 class=\"jump\">|<p class=\"content_text\" lang=\"en\" dir=\"ltr\">)";
	NSString *instanceMethodMatch = [contents stringByMatching:regex_instanceMethodBlock
													   options:(RKLDotAll|RKLCaseless)
													   inRange:NSMakeRange(0, [contents length])
													   capture:0
														 error:nil];
	
	if ([instanceMethodMatch length])
	{
		NSEntityDescription *methodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:ctx];
		
		NSString *regex_instanceMethod = [NSString stringWithFormat:@"<a name=\"//apple_ref/occ/instm/%@/([a-zA-Z0-9_$:]+)\" title=\"([a-zA-Z0-9_$:]+)\">", name];
		NSArray *methods = [instanceMethodMatch componentsSeparatedByRegex:regex_instanceMethod];
		
		for (NSString *method in methods)
		{			
			//Method name
			NSString *methodName = [method stringByMatching:@"<h3 class=\"jump instanceMethod\">([^<>]+)</h3>" capture:1];
			if (methodName == nil)
				continue;
			
			IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:methodEntity insertIntoManagedObjectContext:ctx];
			
			//Method abstract
			NSString *methodAbstract = [method stringByMatching:@"</h3>\\s*<p class=\"spaceabove\">([^<>]+)</p>" capture:1];
			
			//Method Signature
			NSString *methodSignature = [method stringByMatching:@"<p class=\"spaceabovemethod\">(.+?)</p>" capture:1];
			methodSignature = [methodSignature stringByReplacingOccurrencesOfRegex:@"<a\\s+[^>]+>(.+?)</a>" withString:@"$1"];
			
			[newMethod setValue:methodName forKey:@"name"];
			[newMethod setValue:obj forKey:@"container"];
			[newMethod setValue:docset forKey:@"docset"];
			[newMethod setValue:methodSignature forKey:@"signature"];
			
			if ([methodAbstract length])
				[newMethod setValue:methodAbstract forKey:@"overview"];
		}
	}
	
	
	return YES;
}


#pragma mark -- NSXMLDocument Indexing Helper Methods

- (void)createMethodNamed:(NSString *)name description:(NSString *)description prototype:(NSString *)prototype methodEntity:(NSEntityDescription *)methodEntity parent:(NSManagedObject*)parent docset:(NSManagedObject*)docset
{
	if (name == nil)
		return;
	
	//NSLog(@"createMethodNamed = %@", name);
	IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:methodEntity insertIntoManagedObjectContext:ctx];
	
	[newMethod setValue:name forKey:@"name"];
	
	if ([description length])
		[newMethod setValue:description forKey:@"overview"];
	
	[newMethod setValue:prototype forKey:@"signature"];
	
	[newMethod setValue:parent forKey:@"container"];
	[newMethod setValue:docset forKey:@"docset"];
}

- (NSArray *)splitArray:(NSArray *)array byBlock:(BOOL (^)(id a))block
{
	NSMutableArray *arrays = [[NSMutableArray alloc] init];
	
	NSMutableArray *currentArray = [[NSMutableArray alloc] init];
	[arrays addObject:currentArray];
	
	for (id a in array)
	{
		if (block(a))
		{
			currentArray = [[NSMutableArray alloc] init];
			[arrays addObject:currentArray];
		}
		else
		{
			[currentArray addObject:a];
		}
	}
	
	return arrays;
}
- (NSArray *)array:(NSArray *)array findObjectByBlock:(BOOL (^)(id a))block
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



#endif
