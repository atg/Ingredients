//
//  IGKFrecencyStore.m
//  Ingredients
//
//  Created by Alex Gordon on 01/07/2010.
//  Written in 2010 by Fileability.
//

#import "IGKFrecencyStore.h"


typedef struct {
	int64_t timestamp;
	NSString *item;
	
	// IF YOU MODIFY THIS STRUCT YOU ******MUST****** INCREMENT IGKFrecencyStoreBufferRecordVersion !!!!!!1!1!!!!1!ONE!1!!ELEVENTY1
	
} IGKFrecencyStoreBufferRecord;

// vvvvv THAT'S THIS THING vvvvv
const int IGKFrecencyStoreBufferRecordVersion = 1;
// ^^^^^^ ^^^^^^^^^^^^^^^^ ^^^^^


@interface IGKFrecencyStore ()

- (NSString *)storeDirectory;
- (NSString *)storeExtension;
- (NSString *)path;
- (void)readFromDisk;
- (void)writeToDisk;
- (void)heartbeat;

@end


@implementation IGKFrecencyStore

#pragma mark Life Cycle

static NSMutableDictionary *stores = nil;

+ (id)storeWithIdentifier:(NSString *)ident
{
	return nil;
	
	if ([stores objectForKey:ident])
		return [stores objectForKey:ident];
	
	if (!stores)
		stores = [[NSMutableDictionary alloc] initWithCapacity:5];
	
	IGKFrecencyStore *store = [[[self alloc] initWithIdentifier:ident] autorelease];
	[stores setValue:store forKey:ident];
	
	return store;
}
- (id)initWithIdentifier:(NSString *)ident
{
	if (self = [super init])
	{
		identifier = [ident copy];
		
		[self readFromDisk];
		
		[self heartbeat];
	}
	
	return self;
}
- (void)finalize
{
	IGKCircularBufferFree(buffer);
	
	[super finalize];
}


#pragma mark Recording and Reading

- (void)recordItem:(NSString *)item
{
	int64_t timestamp = (int64_t)[NSDate timeIntervalSinceReferenceDate];
	
	IGKFrecencyStoreBufferRecord record;
	record.timestamp = timestamp;
	record.item = item;
	
	IGKCircularBufferAdd(buffer, &record);
	
	hasChanges = YES;
}
- (NSArray *)timestampsForItem:(NSString *)item count:(uint64_t *)count
{
	//If no variable to put count in is specified, they can't do anything but crash, so return NULL 
	if (!count)
		return NULL;
	
	CFIndex length = IGKCircularBufferRawDataLength(buffer);
	IGKFrecencyStoreBufferRecord* data = (IGKFrecencyStoreBufferRecord*)IGKCircularBufferRawData(buffer);
	
	NSMutableArray *timestamps = [[NSMutableArray alloc] initWithCapacity:100];
	
	if (buffer.elementCount > 0)
	{
		for (CFIndex i = buffer.oldestElement; ; i = (i + 1) % buffer.elementCount)
		{
			if (data + i == NULL)
				continue;
			
			IGKFrecencyStoreBufferRecord record = data[i];
			if ([record.item isEqual:item])
			{
				[timestamps addObject:[NSNumber numberWithLongLong:record.timestamp]];
			}
			
			if (i == buffer.youngestElement)
				break;
		}
	}
	
	return timestamps;
}

#pragma mark File IO

const CFIndex IGKFrecencyStoreMaximumCount = 1000;
const CFIndex IGKFrecencyStoreInitialCount = 100;

- (NSString *)storeDirectory
{
	// <appsupport>/Frecency/<identifier>
	
	NSString *appSupport = [[[NSApp delegate] kitController] applicationSupportDirectory];
	
	return [appSupport stringByAppendingPathComponent:@"Frecency"];
}
- (NSString *)storeExtension
{
	return [NSString stringWithFormat:@"igkfrecencystore%d", IGKFrecencyStoreBufferRecordVersion];
}
- (NSString *)path
{
	return [[[self storeDirectory] stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:[self storeExtension]];
}
- (void)readFromDisk
{
	NSString *path = [self path];
	
	NSError *err = nil;
	NSData *data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingUncached error:&err];
	
	if (!data || err)
	{
		buffer = IGKCircularBufferCreate(IGKFrecencyStoreMaximumCount, sizeof(IGKFrecencyStoreBufferRecord), IGKFrecencyStoreInitialCount);
		return;
	}
	
	//Read from data
	buffer = IGKCircularBufferCreateFromData([data bytes], [data length], IGKFrecencyStoreMaximumCount, sizeof(IGKFrecencyStoreBufferRecord));
}
- (void)writeToDisk
{
	NSLog(@"Writing IGKFrecencyStore %@ to disk. It has%@ changes", identifier, hasChanges ? @"" : @" no");

	if (!hasChanges)
		return;
	hasChanges = NO;
	
	NSString *path = [self path];
	NSLog(@"\t path = '%@'", path);
	
	//Create the directory
	[[NSFileManager defaultManager] createDirectoryAtPath:[self storeDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
	
	//Get data from buffer
	if (buffer.elementCount == 0)
		return;
	NSData *data = IGKCircularBufferOrderedData(buffer);
	NSLog(@"\t data [%ud] %@", [data length], data);
	
	//Write to disk
	NSError *err = nil;
	[data writeToFile:path options:NSDataWritingAtomic error:&err];
	NSLog(@"\t err = %@", err);
}
- (void)heartbeat
{
	NSLog(@"Heartbeat on IGKFrecencyStore %@", identifier);
	
	[self writeToDisk];
	
	//We want to do a write every 20 seconds
	[self performSelector:@selector(heartbeat) withObject:nil afterDelay:5.0];
}

@end
