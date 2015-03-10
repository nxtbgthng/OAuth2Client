//
//  NXOAuth2FileStreamWrapper.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import "NXOAuth2FileStreamWrapper.h"


@implementation NXOAuth2FileStreamWrapper

#pragma mark Class Methods

+ (instancetype)wrapperWithStream:(NSInputStream *)aStream contentLength:(unsigned long long)aContentLength;
{
    return [self wrapperWithStream:aStream contentLength:aContentLength fileName:nil];
}

+ (instancetype)wrapperWithStream:(NSInputStream *)aStream contentLength:(unsigned long long)aContentLength fileName:(NSString *)aFileName;
{
    return [[self alloc] initWithStream:aStream contentLength:aContentLength fileName:aFileName];
}


#pragma mark Lifecycle

- (instancetype)init;
{
    NSAssert(NO, @"-init should not be used in the NXOAuth2FileStreamWrapper");
    return nil;
}

- (instancetype)initWithStream:(NSInputStream *)theStream contentLength:(unsigned long long)theContentLength;
{
    return [self initWithStream:theStream contentLength:theContentLength fileName:nil];
}

- (instancetype)initWithStream:(NSInputStream *)aStream contentLength:(unsigned long long)aContentLength fileName:(NSString *)aFileName;
{
    if (!aFileName) aFileName = @"unknown";
    
    self = [super init];
    if (self) {
        stream = aStream;
        contentLength = aContentLength;
        fileName = [aFileName copy];
        contentType = @"application/octet-stream"; // DEFAULT if not assigned by property
    }
    return self;
}


#pragma mark Accessors

@synthesize stream, contentLength, fileName, contentType;


@end
