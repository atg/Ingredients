//
//  FUCoreDataStore.h
//  Ingredients
//
//  Created by Alex Gordon on 22/04/2011.
//

#import <Cocoa/Cocoa.h>
#import "FMDatabase.h"


// In case you're wondering why I'm going to these lengths to avoid core data...
// Behold! 2 minutes of Core Data doing absolutely nothing: http://chocolatapp.com/snaps/fffffffuuuuuuuuuuuucoredata.png
// Inspiring, isn't it?

@interface FUCoreDataStore : NSObject {
	FMDatabase *database;
	NSManagedObjectContext *context;
	
	NSDictionary *scalarKeyMap; // key -> column name
	NSDictionary *relationshipToEntityMap; // key -> entity name
}

@property (readonly) FMDatabase *database;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctx;
- (id)magicObjectForEntity:(NSString *)normalEntityName rowid:(id)rowid;

@end


@interface NSManagedObjectContext (FUCoreData)

- (FUCoreDataStore *)fffffffuuuuuuuuuuuu;

@end


// An FUCoreDataMagicObject acts a bit like a Core Data object. It overrides valueForKey: and tries to translate the key it's given into a key on the results dictionary
@interface FUCoreDataMagicObject : NSObject {
	FUCoreDataStore *store;
	NSDictionary *scalarKeyMap; // key -> column name
	NSDictionary *relationshipToEntityMap; // key -> entity name
	
	NSDictionary *results; // Value of the database
	
	NSManagedObject *managedObject;
}

@property (assign) FUCoreDataStore *store;
@property (assign) NSDictionary *scalarKeyMap;
@property (assign) NSDictionary *relationshipToEntityMap;
@property (assign) NSDictionary *results;
@property (assign) NSManagedObject *managedObject;

- (id)valueForKey:(id)key;
+ (NSString *)coredataizeKey:(NSString *)normalKey;

@end