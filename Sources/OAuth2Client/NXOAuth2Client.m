//
//  NXOAuth2Client.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Connection.h"
#import "NXOAuth2AccessToken.h"

#import "NSURL+NXOAuth2.h"
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
		  authorizeURL:(NSURL *)anAuthorizeURL
			  tokenURL:(NSURL *)aTokenURL
		   redirectURL:(NSURL *)aRedirectURL
		  authDelegate:(NSObject<NXOAuth2ClientAuthDelegate> *)anAuthDelegate;
{
	NSAssert(aRedirectURL != nil, @"WebServer flow without redirectURL.");
	NSAssert(aTokenURL != nil && anAuthorizeURL != nil, @"No token or no authorize URL");
	if (self = [super init]) {
		clientId = [aClientId copy];
		clientSecret = [aClientSecret copy];
		authorizeURL = [anAuthorizeURL copy];
		tokenURL = [aTokenURL copy];
		redirectURL = [aRedirectURL copy];
		
		authDelegate = anAuthDelegate;
		if (self.accessToken && !self.accessToken.hasExpired) [authDelegate oauthClientDidAuthorize:self];	// if we have a valid access token in the keychain
	}
	return self;
}

- (id)initWithClientID:(NSString *)aClientId
		  clientSecret:(NSString *)aClientSecret
		  authorizeURL:(NSURL *)anAuthorizeURL
			  tokenURL:(NSURL *)aTokenURL
			  username:(NSString *)aUsername
			  password:(NSString *)aPassword
		  authDelegate:(NSObject<NXOAuth2ClientAuthDelegate> *)anAuthDelegate;
{
	NSAssert(aUsername != nil && aPassword != nil, @"Username & password flow without username & password.");
	NSAssert(aTokenURL != nil && anAuthorizeURL != nil, @"No token or no authorize URL");
	if (self = [super init]) {
		clientId = [aClientId copy];
		clientSecret = [aClientSecret copy];
		authorizeURL = [anAuthorizeURL copy];
		tokenURL = [aTokenURL copy];
		username = [aUsername copy];
		password = [aPassword copy];
		
		authDelegate = anAuthDelegate;
		if (self.accessToken && !self.accessToken.hasExpired) [authDelegate oauthClientDidAuthorize:self];	// if we have a valid access token in the keychain
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
	[redirectURL release];
	[username release];
	[password release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize clientId, clientSecret;

@dynamic accessToken;

- (NXOAuth2AccessToken *)accessToken;
{
	if (accessToken) return accessToken;
	accessToken = [NXOAuth2AccessToken tokenFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
	return accessToken;
}

- (void)setAccessToken:(NXOAuth2AccessToken *)value;
{
	if (!value) {
		[self.accessToken removeFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
	}
	
	[self willChangeValueForKey:@"accessToken"];
	[value retain];	[accessToken release]; accessToken = value;
	[self didChangeValueForKey:@"accessToken"];
	
	[accessToken storeInDefaultKeychainWithServiceProviderName:[tokenURL host]];
}


#pragma mark Flow

- (void)requestAccess;
{
	if (self.accessToken) {
		if (self.accessToken.hasExpired){
			[self refreshAccessToken];
		}
	} else if (username != nil && password != nil) {	// username password flow
		[self requestTokenWithUsernameAndPassword];
	} else {									// web server flow
		NSAssert(redirectURL, @"Web server flow without redirectURL");	
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
	
	NSURL *URL = [authorizeURL URLByAddingParameters:[NSDictionary dictionaryWithObjectsAndKeys:
													  @"code", @"response_type",
													  clientId, @"client_id",
													  [redirectURL absoluteString], @"redirect_uri",
													  nil]];
	[authDelegate oauthClient:self requestedAuthorizationWithURL:URL];
}


// Web Server Flow only
- (BOOL)openRedirectURL:(NSURL *)URL;
{
	NSString *accessGrand = [URL valueForQueryParameterKey:@"code"];
	if (accessGrand) {
		[authGrand release];
		authGrand = [accessGrand copy];
		[self requestTokenWithAuthGrand];
		return YES;
	}
	return NO;
}

#pragma mark accessGrand -> accessToken

// Web Server Flow only
- (void)requestTokenWithAuthGrand;
{
	NSAssert(!authConnection, @"invalid state");
	
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"authorization_code", @"grant_type",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 [redirectURL absoluteString], @"redirect_uri",
								 authGrand, @"code",
								 nil]];
	[authConnection release]; // just to be sure
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
													 oauthClient:self
														delegate:self];
}


// User Password Flow Only
- (void)requestTokenWithUsernameAndPassword;
{
	NSAssert(!authConnection, @"invalid state");
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"password", @"grant_type",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 [redirectURL absoluteString], @"redirect_uri",
								 username, @"username",
								 password, @"password",
								 nil]];
	 [authConnection release]; // just to be sure
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
	NSAssert((accessToken.refreshToken != nil), @"invalid state");
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[tokenRequest setParameters:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"refresh_token", @"grant_type",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 accessToken.refreshToken, @"refresh_token",
								 nil]];
	[authConnection release]; // just to be sure
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
													 oauthClient:self
														delegate:self];
	if (retryConnection) {
		if (!retryConnectionsAfterTokenExchange) retryConnectionsAfterTokenExchange = [[NSMutableArray alloc] init];
		[retryConnectionsAfterTokenExchange addObject:retryConnection];
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
		[authDelegate oauthClientDidAuthorize:self];
		
		for (NXOAuth2Connection *retryConnection in retryConnectionsAfterTokenExchange) {
			[retryConnection retry];
		}
		[retryConnectionsAfterTokenExchange removeAllObjects];
	}
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
	if (connection == authConnection) {
		[authDelegate oauthClient:self didFailToAuthorizeWithError:error]; // TODO: create own error domain?
	}
}


@end
