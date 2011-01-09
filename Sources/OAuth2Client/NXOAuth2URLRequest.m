//
//  NXOAuth2URLRequest.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 10.12.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NSURL+NXOAuth2.h"

#import "NXOAuth2PostBodyStream.h"

#import "NXOAuth2URLRequest.h"


@implementation NXOAuth2URLRequest

#pragma mark Lifecycle

- (void)dealloc;
{
	[parameters release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize parameters;

- (void)setParameters:(NSDictionary *)value;
{
	[value retain]; [parameters release]; parameters = value;
	
	NSString *httpMethod = [self HTTPMethod];
	if ([httpMethod caseInsensitiveCompare:@"POST"] != NSOrderedSame
		&& [httpMethod caseInsensitiveCompare:@"PUT"] != NSOrderedSame) {
		self.URL = [self.URL nxoauth2_URLByAddingParameters:parameters];
	} else {
		[self resetHTTPBodyStream];
	}
}


#pragma mark Managing Body Stream

- (void)resetHTTPBodyStream;
{
	NSString *httpMethod = [self HTTPMethod];
	if ([httpMethod caseInsensitiveCompare:@"POST"] != NSOrderedSame
		&& [httpMethod caseInsensitiveCompare:@"PUT"] != NSOrderedSame) {
		return;
	}
	
	NSInputStream *postBodyStream = [[NXOAuth2PostBodyStream alloc] initWithParameters:self.parameters];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", [(NXOAuth2PostBodyStream *)postBodyStream boundary]];
	NSString *contentLength = [NSString stringWithFormat:@"%d", [(NXOAuth2PostBodyStream *)postBodyStream length]];
	[self setValue:contentType forHTTPHeaderField:@"Content-Type"];
	[self setValue:contentLength forHTTPHeaderField:@"Content-Length"];
	
	[self setHTTPBodyStream:postBodyStream];
	[postBodyStream release];
}

@end
