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
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2AccessToken.h"

#import "NSURL+NXOAuth2.h"

#import "NXOAuth2ClientAuthDelegate.h"

#import "NXOAuth2Client.h"


NSString * const NXOAuth2ClientConnectionContextTokenRequest = @"tokenRequest";
NSString * const NXOAuth2ClientConnectionContextTokenRefresh = @"tokenRefresh";


@interface NXOAuth2Client ()
- (void)requestTokenWithAuthGrant:(NSString *)authGrant redirectURL:(NSURL *)redirectURL;
- (void)removeConnectionFromWaitingQueue:(NXOAuth2Connection *)aConnection;
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
	self = [super init];
	if (self) {
		refreshConnectionDidRetryCount = 0;
		
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
	[waitingConnections release];
	[authConnection cancel];
	[authConnection release];
	[userAgent release];
	[clientId release];
	[clientSecret release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize clientId, clientSecret, userAgent, delegate, persistent, accessToken;

- (void) setPersistent:(BOOL)shouldPersist;
{
	if (persistent == shouldPersist) return;
	
	if (shouldPersist && accessToken) {
		[self.accessToken storeInDefaultKeychainWithServiceProviderName:[tokenURL host]];
	}
	
	if (!shouldPersist) {
		[self.accessToken removeFromDefaultKeychainWithServiceProviderName:[tokenURL host]];		
	}
	
	[self willChangeValueForKey:@"persistent"];
	persistent = shouldPersist;
	[self didChangeValueForKey:@"persistent"];
}

- (NXOAuth2AccessToken *)accessToken;
{
	if (accessToken) return accessToken;
	
	if (persistent) {
		accessToken = [[NXOAuth2AccessToken tokenFromDefaultKeychainWithServiceProviderName:[tokenURL host]] retain];
		if (accessToken) {
			[delegate oauthClientDidGetAccessToken:self];
		}
		return accessToken;
	} else {
		return nil;
	}
}

- (void)setAccessToken:(NXOAuth2AccessToken *)value;
{
	if (self.accessToken == value) return;
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
		[delegate oauthClientNeedsAuthentication:self];
	}
}

- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;
{
	return [authorizeURL nxoauth2_URLByAddingParameters:[NSDictionary dictionaryWithObjectsAndKeys:
														 @"code", @"response_type",
														 clientId, @"client_id",
														 [redirectURL absoluteString], @"redirect_uri",
														 nil]];
}


// Web Server Flow only
- (BOOL)openRedirectURL:(NSURL *)URL;
{
	NSString *accessGrant = [URL nxoauth2_valueForQueryParameterKey:@"code"];
	if (accessGrant) {
		[self requestTokenWithAuthGrant:accessGrant redirectURL:[URL nxoauth2_URLWithoutQueryString]];
		return YES;
	}
	
	NSString *errorString = [URL nxoauth2_valueForQueryParameterKey:@"error"];
	if (errorString) {
		NSInteger errorCode = 0;
		NSString *localizedError = nil;
		
		if ([errorString caseInsensitiveCompare:@"invalid_request"] == NSOrderedSame) {
			errorCode = NXOAuth2InvalidRequestErrorCode;
			localizedError = NSLocalizedString(@"Invalid request to OAuth2 Server", @"NXOAuth2InvalidRequestErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"invalid_client"] == NSOrderedSame) {
			errorCode = NXOAuth2InvalidClientErrorCode;
			localizedError = NSLocalizedString(@"Invalid OAuth2 Client", @"NXOAuth2InvalidClientErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"unauthorized_client"] == NSOrderedSame) {
			errorCode = NXOAuth2UnauthorizedClientErrorCode;
			localizedError = NSLocalizedString(@"Unauthorized Client", @"NXOAuth2UnauthorizedClientErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"redirect_uri_mismatch"] == NSOrderedSame) {
			errorCode = NXOAuth2RedirectURIMismatchErrorCode;
			localizedError = NSLocalizedString(@"Redirect URI mismatch", @"NXOAuth2RedirectURIMismatchErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"access_denied"] == NSOrderedSame) {
			errorCode = NXOAuth2AccessDeniedErrorCode;
			localizedError = NSLocalizedString(@"Access denied", @"NXOAuth2AccessDeniedErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"unsupported_response_type"] == NSOrderedSame) {
			errorCode = NXOAuth2UnsupportedResponseTypeErrorCode;
			localizedError = NSLocalizedString(@"Unsupported response type", @"NXOAuth2UnsupportedResponseTypeErrorCode description");
			
		} else if ([errorString caseInsensitiveCompare:@"invalid_scope"] == NSOrderedSame) {
			errorCode = NXOAuth2InvalidScopeErrorCode;
			localizedError = NSLocalizedString(@"Invalid scope", @"NXOAuth2InvalidScopeErrorCode description");
		}
		
		if (errorCode != 0) {
			NSDictionary *userInfo = nil;
			if (localizedError) {
				userInfo = [NSDictionary dictionaryWithObject:localizedError forKey:NSLocalizedDescriptionKey];
			}
			[delegate oauthClient:self didFailToGetAccessTokenWithError:[NSError errorWithDomain:NXOAuth2ErrorDomain
																							code:errorCode
																						userInfo:userInfo]];
		}
	}
	return NO;
}

#pragma mark Request Token

// Web Server Flow only
- (void)requestTokenWithAuthGrant:(NSString *)authGrant redirectURL:(NSURL *)redirectURL;
{
	NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
	
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[authConnection cancel]; [authConnection release]; // just to be sure
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
											   requestParameters:[NSDictionary dictionaryWithObjectsAndKeys:
																  @"authorization_code", @"grant_type",
																  clientId, @"client_id",
																  clientSecret, @"client_secret",
																  [redirectURL absoluteString], @"redirect_uri",
																  authGrant, @"code",
																  nil]
													 oauthClient:self
														delegate:self];
	authConnection.context = NXOAuth2ClientConnectionContextTokenRequest;
}


// User Password Flow Only
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;
{
	NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
	
	NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
	[tokenRequest setHTTPMethod:@"POST"];
	[authConnection cancel]; [authConnection release]; // just to be sure
	authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
											   requestParameters:[NSDictionary dictionaryWithObjectsAndKeys:
																  @"password", @"grant_type",
																  clientId, @"client_id",
																  clientSecret, @"client_secret",
																  username, @"username",
																  password, @"password",
																  nil]
													 oauthClient:self
														delegate:self];
	authConnection.context = NXOAuth2ClientConnectionContextTokenRequest;
}


#pragma mark Public

- (void)refreshAccessToken;
{
	[self refreshAccessTokenAndRetryConnection:nil];
}

- (void)refreshAccessTokenAndRetryConnection:(NXOAuth2Connection *)retryConnection;
{
	if (retryConnection) {
		if (!waitingConnections) waitingConnections = [[NSMutableArray alloc] init];
		[waitingConnections addObject:retryConnection];
	}
	if (!authConnection) {
		NSAssert((accessToken.refreshToken != nil), @"invalid state");
		NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
		[tokenRequest setHTTPMethod:@"POST"];
		[authConnection cancel]; [authConnection release]; // not needed, but looks more clean to me :)
		authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
												   requestParameters:[NSDictionary dictionaryWithObjectsAndKeys:
																	  @"refresh_token", @"grant_type",
																	  clientId, @"client_id",
																	  clientSecret, @"client_secret",
																	  accessToken.refreshToken, @"refresh_token",
																	  nil]
														 oauthClient:nil
															delegate:self];
		authConnection.context = NXOAuth2ClientConnectionContextTokenRefresh;
	}
}

- (void)removeConnectionFromWaitingQueue:(NXOAuth2Connection *)aConnection;
{
	if (!aConnection) return;
    [waitingConnections removeObject:aConnection];
}


#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
	if (connection == authConnection) {
		NSString *result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NXOAuth2AccessToken *newToken = [NXOAuth2AccessToken tokenWithResponseBody:result];
		NSAssert(newToken != nil, @"invalid response?");
		self.accessToken = newToken;
		
		for (NXOAuth2Connection *retryConnection in waitingConnections) {
			[retryConnection retry];
		}
		[waitingConnections removeAllObjects];
		
		[authConnection release]; authConnection = nil;
		
		refreshConnectionDidRetryCount = 0;	// reset
	}
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
	if (connection == authConnection) {
		id context = [[connection.context retain] autorelease];
		[authConnection release]; authConnection = nil;
		
		if ([context isEqualToString:NXOAuth2ClientConnectionContextTokenRefresh]
			&& [[error domain] isEqualToString:NXOAuth2HTTPErrorDomain]
			&& error.code >= 500 && error.code < 600
			&& refreshConnectionDidRetryCount < 4) {
			
			// no token refresh because of a server issue. don't give up just yet.
			[self performSelector:@selector(refreshAccessToken) withObject:nil afterDelay:1];
			refreshConnectionDidRetryCount++;
			
		} else {
			if ([context isEqualToString:NXOAuth2ClientConnectionContextTokenRefresh]) {
				NSError *retryFailedError = [NSError errorWithDomain:NXOAuth2ErrorDomain
																code:NXOAuth2CouldNotRefreshTokenErrorCode
															userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	  NSLocalizedString(@"Access token could not be refreshed", @"NXOAuth2CouldNotRefreshTokenErrorCode description"), NSLocalizedDescriptionKey,
																	  nil]];
				for (NXOAuth2Connection *retryConnection in waitingConnections) {
					id<NXOAuth2ConnectionDelegate> connectionDelegate = retryConnection.delegate;
					if ([connectionDelegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
						[connectionDelegate oauthConnection:retryConnection didFailWithError:retryFailedError];
					}
				}
				[waitingConnections removeAllObjects];
			}
			
			if ([[error domain] isEqualToString:NXOAuth2HTTPErrorDomain]
				&& error.code == 401) {
				self.accessToken = nil;		// reset the token since it got invalid
			}
			
			[delegate oauthClient:self didFailToGetAccessTokenWithError:error];
		}
	}
}


@end
