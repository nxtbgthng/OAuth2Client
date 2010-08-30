//
//  NXOAuth2Client.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Connection.h"

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
	
	NSURL *URL = [authorizeURL URLByAddingParameters:[NSDictionary dictionaryWithObjectsAndKeys:
													  @"code", @"response_type",
													  clientId, @"client_id",
													  [redirectURL absoluteString], @"redirect_uri",
													  nil]];
	[authDelegate oauthClient:self requestedAuthorizationWithURL:URL];
}


// Web Server Flow only
- (BOOL)openURL:(NSURL *)URL;
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
								 authGrand, @"code",
								 redirectURL, @"redirect_uri",
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
								 @"authorization_code", @"password",
								 clientId, @"client_id",
								 clientSecret, @"client_secret",
								 username, @"username",
								 password, @"password",
								 nil]];
	 [authConnection release]; // just to be sure
	 authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
													  oauthClient:self
														 delegate:self];
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
