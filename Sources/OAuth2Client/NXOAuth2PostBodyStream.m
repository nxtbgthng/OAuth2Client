/*
 *  NXOAuth2PostBodyStream.m
 *  OAuth2Client
 *
 *  Created by Ullrich Schäfer on 27.08.10.
 *  Copyright 2010 nxtbgthng. All rights reserved. 
 *  Licenced under the new BSD-licence.
 *  See README.md in this reprository for 
 *  the full licence.
 *
 */

#import "NXOAuth2PostBodyPart.h"
#import "NXOAuth2PostBodyStreamMonitorDelegate.h"

#import "NXOAuth2PostBodyStream.h"


@interface NXOAuth2PostBodyStream ()
- (NSArray *)streamsForParameters:(NSDictionary *)bodyParts contentLength:(unsigned long long *)contentLength;
@end


@implementation NXOAuth2PostBodyStream

#pragma mark Lifecycle

- (id)initWithParameters:(NSDictionary *)postParameters;
{
	if (self = [self init]) {
		srandom(time(NULL));
		boundary = [[NSString alloc] initWithFormat:@"------------nx-oauth2%d", rand()];
		numBytesTotal = 0;
		numBytesRead = 0;
		streamIndex = 0;
		
		if (postParameters) {
			contentStreams = [[self streamsForParameters:postParameters contentLength:&numBytesTotal] retain];
		} else {
			contentStreams = [[NSArray alloc] init];
		}
	}
	return self;
}

- (void)dealloc;
{
	[boundary release];
	[contentStreams release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize monitorDelegate = monitorDelegate;
@synthesize length = numBytesTotal;
@synthesize boundary;


#pragma mark private

- (NSArray *)partsForParameters:(NSDictionary *)parameters;
{
	NSMutableArray *parts = [NSMutableArray array];
	for (NSString *key in parameters) {
		id value = [parameters valueForKey:key];
		if ([value isKindOfClass:[NSArray class]]) {
			NSArray *contentArray = (NSArray *)value;
			for (id content in contentArray) {
				NXOAuth2PostBodyPart *part = [[NXOAuth2PostBodyPart alloc] initWithName:key content:content];
				[parts addObject:part];
				[part release];
			}
		} else {
			NXOAuth2PostBodyPart *part = [[NXOAuth2PostBodyPart alloc] initWithName:key content:value];
			[parts addObject:part];
			[part release];
		}
	}
	return parts;
}

- (NSArray *)streamsForParameters:(NSDictionary *)parameters contentLength:(unsigned long long *)contentLength;
{
	NSArray *parts = [self partsForParameters:parameters];
	NSMutableArray *streams = [NSMutableArray array];
	
	NSString *firstDelimiter = [NSString stringWithFormat: @"--%@\r\n", boundary];
    NSString *middleDelimiter = [NSString stringWithFormat: @"\r\n--%@\r\n", boundary];
    NSString *finalDelimiter = [NSString stringWithFormat: @"\r\n--%@--\r\n", boundary];
	
    NSString *delimiter = firstDelimiter;
    for (NXOAuth2PostBodyPart *part in parts) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSData *delimiterData = [delimiter dataUsingEncoding:NSUTF8StringEncoding];
		NSData *contentHeaderData = [[part contentHeaders] dataUsingEncoding:NSUTF8StringEncoding];
		
		int dataLength = delimiterData.length + contentHeaderData.length;
        NSMutableData *headerData = [NSMutableData dataWithCapacity: dataLength];
        [headerData appendData:delimiterData];
        [headerData appendData:contentHeaderData];
		
        NSInputStream *headerStream = [NSInputStream inputStreamWithData:headerData];
        [streams addObject:headerStream];
        *contentLength += [headerData length];
		
        [streams addObject:[part contentStream]];
        *contentLength += [part contentLength];
        
        delimiter = middleDelimiter;
		
		[pool release];
    }
    
    NSData *finalDelimiterData = [finalDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    NSInputStream *finalDelimiterStream = [NSInputStream inputStreamWithData:finalDelimiterData];
    [streams addObject:finalDelimiterStream];
    *contentLength += [finalDelimiterData length];
	
	return streams;
}

#pragma mark NSInputStream subclassing

- (void)open;
{
	NSAssert((contentStreams != nil) && (boundary != nil), @"Stream has been reopened after close");
    [contentStreams makeObjectsPerformSelector:@selector(open)];
    currentStream = nil;
	streamIndex = 0;
    if (contentStreams.count > 0)
        currentStream = [contentStreams objectAtIndex: streamIndex];
}

- (void)close;
{
	[contentStreams makeObjectsPerformSelector:@selector(close)];
	[contentStreams release]; contentStreams = nil;
	[boundary release]; boundary = nil;
	currentStream = nil;
}

- (BOOL)hasBytesAvailable;
{
	// returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
	return YES;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
{
	if (currentStream == nil)
        return 0;
	
    int result = [currentStream read:buffer maxLength:len];
	
    if (result == 0) {
		if (streamIndex < contentStreams.count - 1) {
			streamIndex++;
			currentStream = [contentStreams objectAtIndex:streamIndex];
			result = [self read:buffer maxLength:len];
		} else {
			currentStream == nil;
		}
	} else {
		numBytesRead += result;
		if([monitorDelegate respondsToSelector:@selector(stream:didSendBytes:ofTotal:)]) {
			[monitorDelegate stream:self didSendBytes:numBytesRead ofTotal:numBytesTotal];
		}
	}
    return result;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len;
{
	return NO;
}

- (NSStreamStatus)streamStatus;
{
	NSStreamStatus status = NSStreamStatusNotOpen;
	
	if (currentStream != nil) {
		status = [currentStream streamStatus];
		if ((status == NSStreamStatusAtEnd || status == NSStreamStatusClosed)
			&& streamIndex < [contentStreams count] - 1)
			status = NSStreamStatusReading;
	}
	
	return status;
}

- (NSError *)streamError;
{
	if(currentStream)
		return [currentStream streamError];
	return nil;
}


#pragma mark Runloop

- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
{
	[super scheduleInRunLoop:runLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
{
	[super removeFromRunLoop:runLoop forMode:mode];
}


#pragma mark NSURLConnection Hacks

- (void)_scheduleInCFRunLoop:(NSRunLoop *)inRunLoop forMode:(id)inMode;
{
    // Safe to ignore this?
	// maybe call this on all child streams?
}

- (void)_setCFClientFlags:(CFOptionFlags)inFlags
				 callback:(CFReadStreamClientCallBack)inCallback
				  context:(CFStreamClientContext)inContext;
{
    // Safe to ignore this?
	// maybe call this on all child streams?
}

@end
