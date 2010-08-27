//
//  NXOAuth2Client.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Client.h"


@implementation NXOAuth2Client


#pragma mark Lifecycle

- (id)initWithClientID:(NSString *)aClientId
		  clientSecret:(NSString *)aClientSecret
		   redirectURL:(NSURL *)aRedirectURL;
{
	NSAssert(aRedirectURL != nil, @"WebServer flow without redirectURL.");
	if (self = [super init]) {
		clientId = [aClientId copy];
		clientSecret = [aClientSecret copy];
		redirectURL = [aRedirectURL copy];
	}
	return self;
}

- (id)initWithClientID:(NSString *)aClientId
		  clientSecret:(NSString *)aClientSecret
			  username:(NSString *)aUsername
			  password:(NSString *)aPassword;
{
	NSAssert(aUsername != nil && aPassword != nil, @"Username & password flow without username & password.");
	if (self = [super init]) {
		clientId = [aClientId copy];
		clientSecret = [aClientSecret copy];
		username = [aUsername copy];
		password = [aPassword copy];
	}
	return self;	
}

- (void)dealloc;
{
	[clientId release];
	[clientSecret release];
	[redirectURL release];
	[username release];
	[password release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize clientId, clientSecret;


#pragma mark Flow


- (void)requestAccessGrand;
{
	if (!redirectURL) { // we're using username & password flow
		NSAssert(username != nil && password != nil, @"Username & password flow without username & password.");
		return;
	}
	
	
}


@end
