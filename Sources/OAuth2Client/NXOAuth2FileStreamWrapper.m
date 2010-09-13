//
//  NXOAuth2FileStreamWrapper.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NXOAuth2FileStreamWrapper.h"


@implementation NXOAuth2FileStreamWrapper

#pragma mark Lifecycle

//TODO: Disable simple Init!

+ (id)wrapperWithStream:(NSInputStream *)theStream contentLength:(unsigned long long)theContentLength;
{
	return [[[self alloc] initWithStream:theStream contentLength:theContentLength] autorelease];
}

- (id)initWithStream:(NSInputStream *)theStream contentLength:(unsigned long long)theContentLength;
{
	if (self = [super init]) {
		stream = [theStream retain];
		contentLength = theContentLength;
	}
	return self;
}

- (void)dealloc;
{
	[stream release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize stream, contentLength;


@end
