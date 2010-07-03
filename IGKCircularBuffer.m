#import "IGKCircularBuffer.h"

IGKCircularBuffer IGKCircularBufferCreateFromData(const void *data, CFIndex dataLength, CFIndex maximumCount, CFIndex elementSize)
{
	IGKCircularBuffer buffer;
	
	buffer.elementCount = 0;
	buffer.allocatedCount = dataLength / elementSize;
	buffer.maximumCount = maximumCount;
	buffer.elementSize = elementSize;
	
	buffer.items = malloc(dataLength * elementSize);
	memcpy(buffer.items, data, dataLength);
	
	buffer.oldestElement = -1;
	buffer.youngestElement = -1;
	
	return buffer;
}

//Create an empty buffer with a specified size
IGKCircularBuffer IGKCircularBufferCreate(CFIndex maximumCount, CFIndex elementSize, CFIndex initialSize)
{
	IGKCircularBuffer buffer;
	
	buffer.elementCount = 0;
	buffer.allocatedCount = initialSize;
	buffer.maximumCount = maximumCount;
	buffer.elementSize = elementSize;
	
	buffer.items = malloc(initialSize * elementSize);
	buffer.oldestElement = -1;
	buffer.youngestElement = -1;
	
	return buffer;
}

void* IGKCircularBufferElementAt(IGKCircularBuffer buffer, CFIndex index)
{
	return buffer.items + index * buffer.elementSize;
}

//Add elementSize bytes of *pointerToData to the buffer.
void IGKCircularBufferAdd(IGKCircularBuffer buffer, void* pointerToData)
{
	//If the buffer needs to grow
	if (buffer.elementCount + 1 > buffer.allocatedCount && buffer.allocatedCount < buffer.maximumCount)
	{
		//Work out a new size for the buffer
		CFIndex newCount;
		if (buffer.allocatedCount * 2 < buffer.maximumCount)
			newCount = buffer.allocatedCount * 2;
		else
			newCount = buffer.maximumCount;
		
		//Allocate some new memory
		void *newItems = NULL;
		newItems = reallocf(buffer.items, buffer.elementSize * newCount);
		if (!newItems)
		{
			//Do something if reallocf fails
			return;
		}
		
		//Set our variables
		buffer.items = newItems;
		buffer.allocatedCount = newCount;
	}
	
	//Is there space for another element?
	_Bool hasSpace = buffer.allocatedCount >= buffer.elementCount + 1;
	
	//If there is space, simply copy over the data and continue on our way
	if (hasSpace)
	{
		//Get the slot
		void* emptySlot = IGKCircularBufferElementAt(buffer, buffer.elementCount);
		
		//Copy the data
		memcpy(emptySlot, pointerToData, buffer.elementSize);
		
		//Set variables
		buffer.youngestElement = buffer.elementCount;
		buffer.elementCount += 1;
		
		//If we haven't set an oldest element yet (ie the buffer was empty), we must do so
		if (buffer.oldestElement == -1)
			buffer.oldestElement = buffer.youngestElement;
	}
	
	//If there's not enough space, we have to make space
	else
	{
		//We insert at oldestElement
		void* vacatedSlot = IGKCircularBufferElementAt(buffer, buffer.oldestElement);
		
		//Since we're inserting at oldestElement, youngestElement becomes oldestElement
		buffer.youngestElement = buffer.oldestElement;
		
		//oldestElement gets incremented modulo maximumCount
		buffer.oldestElement = (buffer.oldestElement + 1) % buffer.maximumCount;
		
		//Copy the memory into the vacated slot
		memcpy(vacatedSlot, pointerToData, buffer.elementSize);
	}
	
	//We're done!
}

//Get a pointer to the raw data and the length of the data, eg to pass to NSData
void* IGKCircularBufferRawData(IGKCircularBuffer buffer)
{
	return buffer.items;
}
CFIndex IGKCircularBufferRawDataLength(IGKCircularBuffer buffer)
{
	if (buffer.items)
		return buffer.elementCount * buffer.elementSize;
	return 0;
}

//Get data in a format suitable for writing out to disk
NSData* IGKCircularBufferOrderedData(IGKCircularBuffer buffer)
{
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:IGKCircularBufferOrderedDataLength(buffer)];
	
	if (buffer.elementCount == 0)
		return data;
	
	for (CFIndex i = buffer.oldestElement; ; i = (i + 1) % buffer.elementCount)
	{
		if (buffer.items + i == NULL)
			continue;
		
		[data appendBytes:buffer.items + i * buffer.elementSize length:buffer.elementSize];
		
		if (i == buffer.youngestElement)
			break;
	}
	
	return data;
}
CFIndex IGKCircularBufferOrderedDataLength(IGKCircularBuffer buffer)
{
	if (buffer.items)
		return buffer.elementCount * buffer.elementSize;
	return 0;
}

//Delete the buffer
void IGKCircularBufferFree(IGKCircularBuffer buffer)
{
	if (buffer.items)
		free(buffer.items);
}