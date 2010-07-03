typedef struct {
	// 0 <= elementCount <= actualSize <= targetSize
	
	//The number of elements in the buffer
	CFIndex elementCount;
	
	//The amount of elements that we have allocated enough memory to hold. Must not be 0
	CFIndex allocatedCount;
	
	//The maximum number of elements that the buffer will grow to hold before it starts discarding things
	CFIndex maximumCount;
	
	//The size in bytes of each element in the buffer
	CFIndex elementSize;
	
	//A pointer to all the elements
	void* items;
	
	//The offset of the element that was added the longest time ago
	CFIndex oldestElement;
	
	//The offset of the element that was added most recently
	CFIndex youngestElement;
	
} IGKCircularBuffer;

//Create a buffer and fill it with data
IGKCircularBuffer IGKCircularBufferCreateFromData(const void *data, CFIndex dataLength, CFIndex maximumCount, CFIndex elementSize);

//Create an empty buffer with a specified size
IGKCircularBuffer IGKCircularBufferCreate(CFIndex maximumCount, CFIndex elementSize, CFIndex initialSize);

//Add elementSize bytes of *pointerToData to the buffer.
void IGKCircularBufferAdd(IGKCircularBuffer buffer, void* pointerToData);

//Get a pointer to the raw data and the length of the data, eg to pass to NSData
void* IGKCircularBufferRawData(IGKCircularBuffer buffer);
CFIndex IGKCircularBufferRawDataLength(IGKCircularBuffer buffer);

//Get data in a format suitable for writing out to disk
NSData* IGKCircularBufferOrderedData(IGKCircularBuffer buffer);
CFIndex IGKCircularBufferOrderedDataLength(IGKCircularBuffer buffer);

//Delete the buffer
void IGKCircularBufferFree(IGKCircularBuffer buffer);
