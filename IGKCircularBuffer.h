typedef struct {
	// 0 <= elementCount <= actualSize <= targetSize
	
	//The number of elements in the buffer
	size_t elementCount;
	
	//The amount of elements that we have allocated enough memory to hold. Must not be 0
	size_t allocatedCount;
	
	//The maximum number of elements that the buffer will grow to hold before it starts discarding things
	size_t maximumCount;
	
	//The size in bytes of each element in the buffer
	size_t elementSize;
	
	//A pointer to all the elements
	void* items;
	
	//The offset of the element that was added the longest time ago
	size_t oldestElement;
	
	//The offset of the element that was added most recently
	size_t youngestElement;
	
} IGKCircularBuffer;

//Create an empty buffer with a specified size
IGKCircularBuffer IGKCircularBufferCreate(size_t maximumCount, size_t elementSize, size_t initialSize);

//Add elementSize bytes of *pointerToData to the buffer.
void IGKCircularBufferAdd(IGKCircularBuffer buffer, void* pointerToData);

//Get a pointer to the raw data and the length of the data, eg to pass to NSData
IGKCircularBuffer IGKCircularBufferRawData(IGKCircularBuffer buffer);
size_t IGKCircularBufferRawDataLength(IGKCircularBuffer buffer);

//Delete the buffer
void IGKCircularBufferFree(IGKCircularBuffer buffer);
