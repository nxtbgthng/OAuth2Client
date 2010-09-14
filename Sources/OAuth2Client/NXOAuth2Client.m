//
//  NXOAuth2Client.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved. 
//
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NXOAuth2Connection.h"
#import "NXOAuth2AccessToken.h"

#import "NSURL+NXOAuth2.h"
#import "NSMutableURLRequest+NXOAuth2.h"

#import "NXOAuth2Client.h"


@interface NXOAuth2Client ()
- (void)requestTokenWithAuthGrand:(NSString *)authGrand redirectURL:(NSURL *)redirectURL;
@end


@implementation NXOAuth2Client


#pragma mark Lifecycle

- (id)initWithClientID:(NSString *)aClientId
		  clientSecret:(NSString *)aClientSecret
		  authorizeURL:(NSURL *)anAuthorizeURL
			  tokenURL:(NSURL *)aTokenURL
              delegate:(NSObject<NXOAuth2ClientDelegate> *)aDelegate;
{
	NSAssert(aTokenURL != nil && anAuthorizeURL != nil, @"No token or no authorize URL");
	if (self = [super init]) {
		clientId = [aClientId copy];
		clientSecret = [aClientSecret copy];
		authorizeURL = [anAuthorizeURL copy];
		tokenURL = [aTokenURL copy];
		
		self.delegate = aDelegate;
	}
	return self;
}

- (void)dealloc;
{
	[retryConnectionsAfterTokenExchange release];
	[authConnection cancel];
	[authConnection release];
	[clientId release];
	[clientSecret release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize clientId, clientSecret, delegate;

@dynamic accessToken;

- (NXOAuth2AccessToken *)accessToken;
{
	if (accessToken) return accessToken;
	accessToken = [[NXOAuth2AccessToken tokenFromDefaultKeychainWithServiceProviderName:[tokenURL host]] retain];
	if (accessToken) {
		[delegate oauthClientDidGetAccessToken:self];
	}
	return accessToken;
}

- (void)setAccessToken:(NXOAuth2AccessToken *)value;
{
	if (accessToken == value) return;
	BOOL didGetOrDidLoseToken = ((accessToken == nil) && (value != nil)		// did get
								  || (accessToken != nil) && (value == nil));	// did lose
	if (!value) {
		[self.accessToken removeFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
	}
	
	[self willChangeValueForKey:@"accessToken"];
	[value retain];	[accessToken release]; accessToken = value;
	[self didChangeValueForKey:@"accessToken"];
	
	[accessToken storeInDefaultKeychainWithServiceProviderName:[tokenURL host]];
	if (didGetOrDidLoseToken) {
		if (accessToken) {
			[delegate oauthClientDidGetAccessToken:self];
		} else {
			[delegate oauthClientDidLoseAccessToken:self];
		}
	}
}


#pragma mark Flow

- (void)requestAccess;
{
	if (!self.accessToken) {
		[delegate oauthClientNeedsAuthorization:self];
	}
}

- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;
{
	return [authorizeURL URLByAddingParameters:[NSDictionary dictionaryWithObjectsAndKeys:
												@"code", @"response_type",
												clientId, @"client_id",
												[redirectURL absoluteString], @"redirect_uri",
												nil]];
}


// Web Server Flow only
- (BOOL)openRedirectURL:(NSURL *)URL;
{
	NSString *accessGrand = [URL valueForQueryParameterKey:@"code"];
	if (accessGrand) {
		[self requestTokenWithAuthGrand:accessGrand redirectURL:[URL URLWithoutQueryString]];
		return YES;
	}
	return NO;
}

#pragma mark accessGrand -> accessToken

// Web Server Flow only
- (void)requestTokenWithAuthGrand:(NSString *)authGrand redirectURL:(NSURL *)redirectURL;
{
	NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
	
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"authorization_code", @"grant_type",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 [redirectURL absoluteString], @"redirect_uri",
								 authGrand, @"code",
								 nil]];
	[authConnection cancel]; [authConnection release]; // just to be sure
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
													 oauthClient:self
														delegate:self];
}


// User Password Flow Only
- (void)authorizeWithUsername:(NSString *)username password:(NSString *)password;
{
	NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
	
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"password", @"grant_type",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 username, @"username",
								 password, @"password",
								 nil]];
	 [authConnection cancel]; [authConnection release]; // just to be sure
	 authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
													  oauthClient:self
														 delegate:self];
}


#pragma mark Public

- (void)refreshAccessToken;
{
	[self refreshAccessTokenAndRetryConnection:nil];
}

- (void)refreshAccessTokenAndRetryConnection:(NXOAuth2Connection *)retryConnection;
{
	if (retryConnection) {
		if (!retryConnectionsAfterTokenExchange) retryConnectionsAfterTokenExchange = [[NSMutableArray alloc] init];
		[retryConnectionsAfterTokenExchange addObject:retryConnection];
	}
	if (!authConnection) {
		NSAssert((accessToken.refreshToken != nil), @"invalid state");
		NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
		[tokenRequest setHTTPMethod:@"POST"];
		[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
									 @"refresh_token", @"grant_type",
									 clientId, @"client_id",
									 clientSecret, @"client_secret",
									 accessToken.refreshToken, @"refresh_token",
									 nil]];
		[authConnection cancel]; [authConnection release]; // not needed, but looks more clean to me :)
		authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
														 oauthClient:nil
															delegate:self];	
	}
}

- (void)abortRetryOfConnection:(NXOAuth2Connection *)retryConnection;
{
	if (retryConnection) {
		[retryConnectionsAfterTokenExchange removeObject:retryConnection];
	}
}


#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
	if (connection == authConnection) {
		NSString *result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NXOAuth2AccessToken *newToken = [NXOAuth2AccessToken tokenWithResponseBody:result];
		NSAssert(newToken != nil, @"invalid response?");
		self.accessToken = newToken;
		
		for (NXOAuth2Connection *retryConnection in retryConnectionsAfterTokenExchange) {
			[retryConnection retry];
		}
		[retryConnectionsAfterTokenExchange removeAllObjects];
		
		[authConnection release]; authConnection = nil;
	}
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
	if (connection == authConnection) {
		[delegate oauthClient:self didFailToGetAccessTokenWithError:error];
		self.accessToken = nil;
		
		[authConnection release]; authConnection = nil;
	}
}


@end
