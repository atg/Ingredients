//
//  IGKScraper.h
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>

@class IGKLaunchController;
@class IGKDocRecordManagedObject;

//A scraper takes a .docset and populates a core data database

@interface IGKScraper : NSObject
{
	NSString *docsetpath;
	NSURL *docsetURL;
	NSURL *url;
	NSManagedObjectContext *ctx;
	
	IGKLaunchController *launchController;
	dispatch_queue_t dbQueue;
	
	NSUInteger pathsCount;
	NSUInteger pathsCounter;
	
	NSMutableArray *paths;
	NSManagedObject *scraperDocset;
	
	NSString *developerDirectory;
}

- (id)initWithDocsetURL:(NSURL *)theDocsetURL managedObjectContext:(NSManagedObjectContext *)moc launchController:(IGKLaunchController*)lc dbQueue:(dispatch_queue_t)dbq developerDirectory:(NSString *)devDir;

- (void)findPathCount;
- (BOOL)findPaths;
- (void)index;

@end



@interface IGKFullScraper : NSObject
{
	IGKDocRecordManagedObject *persistobj;
	
	IGKDocRecordManagedObject *transientObject;
	NSManagedObjectContext *transientContext;
	
	//We use instance variables in IGKFullScraper as a way of maintaining state without passing arguments
	NSManagedObject *docset;
	NSXMLDocument *doc;
	
	NSArray *methodNodes;
	
	BOOL isParsingDeprecatedAppendix;
	
	//Some caching of entities
	NSEntityDescription *ObjCMethodEntity;
	NSEntityDescription *ObjCNotificationEntity;
	NSEntityDescription *ParameterEntity;
	NSEntityDescription *SeeAlsoEntity;
	NSEntityDescription *SampleCodeProjectEntity;
	NSEntityDescription *MetaTaskGroupEntity;
	NSEntityDescription *MetaTaskGroupItemEntity;
	NSEntityDescription *ObjCBindingEntity;
	NSEntityDescription *ObjCBindingOptionEntity;
	NSEntityDescription *ObjCBindingPlaceholderEntity;
}

@property (readonly) NSManagedObject *transientObject;
@property (readonly) NSManagedObjectContext *transientContext;

- (id)initWithManagedObject:(IGKDocRecordManagedObject *)persistentObject;
- (void)start;

- (void)cleanUp;

@end