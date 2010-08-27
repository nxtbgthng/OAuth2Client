//
//  NXOAuth2Client.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Connection.h"

#import "NSMutableURLRequest+NXOAuth2.h"

#import "NXOAuth2Client.h"


@interface NXOAuth2Client ()
- (void)requestAccessGrand;

- (void)requestTokenWithAuthGrand;
- (void)requestTokenWithUsernameAndPassword;
@end


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
	[authConnection cancel];
	[authConnection release];
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


- (void)requestToken;
{
	if (username != nil && password != nil) {	// username password flow
		[self requestTokenWithUsernameAndPassword];
	} else {									// web server flow
		NSAssert(!redirectURL, @"Web server flow without redirectURL");	
		if (authGrand) {	// we have grand already
			[self requestTokenWithAuthGrand];
		} else {
			[self requestAccessGrand];
		}
	}
}

- (void)requestAccessGrand;
{
	if (authConnection) {	// authentication is already running
		return;
	}
	
	NSMutableURLRequest *grandRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.sandbox-soundcloud.com/oauth2/authorize"]];
	[grandRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"code", @"response_type",
								 clientId, @"client_id",
								 nil];
	
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:grandRequest
													 oauthClient:nil			// no need to sign this request. we also haven't got the token yet
														delegate:self];
	[grandRequest release];
}


#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
	NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"result: %@", string);
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
	NSLog(@"Error: %@", [error localizedDescription]);
}


@end
