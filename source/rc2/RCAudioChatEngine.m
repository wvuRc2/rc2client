//
//  RCAudioChatEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 3/2/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCAudioChatEngine.h"
#import "RCSession.h"

@interface RCAudioData : NSObject
-(id)initWithSequence:(int32_t)seq data:(NSData*)inData;
@property (nonatomic, assign) int32_t seqId;
@property (nonatomic, strong) NSData *data;
@end

@interface RCAudioChatEngine() {
	AudioQueueRef _inputQueue, _outputQueue;
	AudioStreamBasicDescription _audioDesc;
	NSMutableArray *_outArray;
	int32_t _audioSeqId;
	BOOL _mikeOn;
}
@property (nonatomic, strong) NSMutableArray *audioQueue;
-(int32_t)bufferSize;
@end

static void MyAudioInputCallback(void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer,
								 const AudioTimeStamp *inStartTIme, UInt32 inNumPackets,
								 const AudioStreamPacketDescription *inPacketDesc);

static void MyOutputCallback(void *inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inCompleteAQBuffer);
static Boolean IsQueueRunning(AudioQueueRef queue);


@implementation RCAudioChatEngine
-(void)initializeRecording
{
	if (_inputQueue)
		return;
#ifdef DEBUG_AUDIO_OUT
	_outArray = [NSMutableArray array];
#endif
	//get the audio format info
	if (0 == _audioDesc.mFormatID) {
		_audioDesc.mFormatID = kAudioFormatiLBC;
		UInt32 propSize = sizeof(AudioStreamBasicDescription);
		AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &_audioDesc);
	}
	MAZeroingWeakRef *weakRef = [MAZeroingWeakRef refWithTarget:self];
	OSStatus err = AudioQueueNewInput(&_audioDesc, MyAudioInputCallback, (__bridge_retained void*)weakRef, NULL, NULL, 0, &_inputQueue);
	if (err != noErr) {
		Rc2LogError(@"failed to create input audio queue: %d", err);
		//TODO: inform user
	}
	for (int i=0; i < 3; i++) {
		AudioQueueBufferRef buffer;
		AudioQueueAllocateBuffer(_inputQueue, self.bufferSize, &buffer);
		AudioQueueEnqueueBuffer(_inputQueue, buffer, 0, NULL);
	}
}

-(void)initializeAudioOut
{
	if (_outputQueue)
		return;
	if (nil == self.audioQueue)
		self.audioQueue = [NSMutableArray array];
	if (0 == _audioDesc.mFormatID) {
		_audioDesc.mFormatID = kAudioFormatiLBC;
		UInt32 propSize = sizeof(AudioStreamBasicDescription);
		AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &_audioDesc);
	}
	OSStatus err = AudioQueueNewOutput(&_audioDesc, MyOutputCallback, (__bridge void*)self, NULL, NULL, 0, &_outputQueue);
	if (noErr != err) {
		//TODO: report error
		Rc2LogError(@"error starting audio output queue:%d", err);
	}
}

//calculate the buffer size. this will only work for iLBC. 
-(int32_t)bufferSize
{
	CGFloat seconds = 0.5f;
	int32_t frames = (int32_t)ceil(seconds * _audioDesc.mSampleRate);
	UInt32 maxPacketSize = _audioDesc.mBytesPerPacket;
	int32_t packets = frames / _audioDesc.mFramesPerPacket;
	int32_t bytes = packets * maxPacketSize;
	return bytes;
}

-(void)toggleMicrophone
{
	if (nil == _inputQueue)
		[self initializeRecording];
	if (_mikeOn) {
		_mikeOn = NO;
		//pause it then
		AudioQueuePause(_inputQueue);
#ifdef DEBUG_AUDIO_OUT
		[_outArray writeToFile:@"/Users/mlilback/Desktop/rc2audio.plist" atomically:NO];
		_outArray = [NSMutableArray array];
#endif
	} else {
		_mikeOn = YES;
		OSStatus status = AudioQueueStart(_inputQueue, NULL);
		if (noErr != status)
			NSLog(@"error starting input queue: %d", (int)status);
	}
}

-(void)resetOutputQueue
{
	AudioQueueBufferRef buffers[3];
	for (int i=0; i < 3; i++) {
		AudioQueueAllocateBuffer(_outputQueue, self.bufferSize, &buffers[i]);
		MyOutputCallback((__bridge void*)self, _outputQueue, buffers[i]);
	}
	AudioQueueStart(_outputQueue, NULL);
}

-(void)outOfAudioOutputData
{
	AudioQueueStop(_outputQueue, false);
}

-(NSData*)popNextAudioOutPacket
{
	NSData *d = nil;
	if (self.audioQueue.count < 1)
		return nil;
	@synchronized (self) {
		RCAudioData *ad = [self.audioQueue lastObject];
		d = ad.data;
		[self.audioQueue removeLastObject];
		if (self.audioQueue.count < 1) {
			NSLog(@"out of audio packets");
			[self outOfAudioOutputData];
		}
	}
	return d;
}

-(void)tearDownAudio
{
	if (_inputQueue) {
		AudioQueueStop(_inputQueue, true);
		AudioQueueDispose(_inputQueue, true);
		_inputQueue=nil;
	}
	if (_outputQueue) {
		AudioQueueStop(_outputQueue, true);
		AudioQueueDispose(_outputQueue, true);
		_outputQueue=nil;
	}
}

-(void)processRecordedData:(AudioQueueBufferRef)inBuffer sampleTime:(int32_t)sampleTime
{
	if (inBuffer->mAudioDataByteSize > 0) {
		NSData *audioData = [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
		NSMutableData *md = [NSMutableData dataWithCapacity:audioData.length + sizeof(_audioSeqId)];
		_audioSeqId = sampleTime;
		[md appendBytes:&_audioSeqId length:sizeof(_audioSeqId)];
		++_audioSeqId;
		[md appendData:audioData];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.session sendAudioInput:md];
		});
#ifdef DEBUG_AUDIO_OUT
		[_outArray addObject:md];
#endif
	}
}

-(void)processBinaryMessage:(NSData*)data
{
	if (nil == _outputQueue) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self initializeAudioOut];
		});
	}
	int32_t audioSeq=0;
	[data getBytes:&audioSeq range:NSMakeRange(0, sizeof(audioSeq))];
	RCAudioData *adata = [[RCAudioData alloc] initWithSequence:audioSeq data:[data subdataWithRange:NSMakeRange(sizeof(audioSeq), data.length - sizeof(audioSeq))]];
	@synchronized (self) {
		if (nil == self.audioQueue)
			self.audioQueue = [NSMutableArray array];
		[self.audioQueue addObject:adata];
		[self.audioQueue sortUsingDescriptors:ARRAY([NSSortDescriptor sortDescriptorWithKey:@"seqId" ascending:NO])];
	}
	if (!IsQueueRunning(_outputQueue) && self.audioQueue.count > 5) {
		AudioQueueBufferRef buffers[3];
		for (int i=0; i < 3; i++) {
			AudioQueueAllocateBuffer(_outputQueue, self.bufferSize, &buffers[i]);
			MyOutputCallback((__bridge void*)self, _outputQueue, buffers[i]);
		}
		AudioQueueStart(_outputQueue, NULL);
	}
}

-(void)playDataFromFile:(NSString*)filePath
{
	if (nil == _outputQueue)
		[self initializeAudioOut];
	NSArray *packetArray = [NSArray arrayWithContentsOfFile:filePath];
	for (NSData *item in packetArray) {
		[self processBinaryMessage:item];
	}
}

@synthesize session=_session;
@synthesize audioQueue=_audioQueue;
@synthesize mikeOn=_mikeOn;
@end

@implementation RCAudioData
-(id)initWithSequence:(int32_t)seq data:(NSData*)inData
{
	self = [super init];
	self.seqId = seq;
	self.data = inData;
	return self;
}
@synthesize seqId;
@synthesize data;
@end

static void MyOutputCallback(void *inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inCompleteAQBuffer)
{
	@autoreleasepool {
		RCAudioChatEngine *me = (__bridge RCAudioChatEngine*)inUserData;
		NSData *data = [me popNextAudioOutPacket];
		if (nil == data || data.length < 1)
			return;
		inCompleteAQBuffer->mAudioDataByteSize = data.length;
		[data getBytes:inCompleteAQBuffer->mAudioData length:inCompleteAQBuffer->mAudioDataByteSize];
		AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
	}
}

static void MyAudioInputCallback(void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer,
								 const AudioTimeStamp *inStartTime, UInt32 inNumPackets,
								 const AudioStreamPacketDescription *inPacketDesc)
{
	dispatch_async(dispatch_get_main_queue(), ^{
		MAZeroingWeakRef *weakRef = (__bridge MAZeroingWeakRef*)inUserData;
		RCAudioChatEngine *me = weakRef.target;
		[me processRecordedData:inBuffer sampleTime:(int)(inStartTime->mSampleTime / 1000)];
		AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, NULL);
	});
}

static Boolean IsQueueRunning(AudioQueueRef queue)
{
	UInt32 val=0;
	UInt32 valSize = sizeof(val);
	AudioQueueGetProperty(queue, kAudioQueueProperty_IsRunning, &val, &valSize);
	return val != 0;
}
