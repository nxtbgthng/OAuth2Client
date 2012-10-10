//
//  NXOAuth2Client.m
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

#import "NXOAuth2Connection.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2AccessToken.h"

#import "NSURL+NXOAuth2.h"

#import "NXOAuth2Client.h"


NSString * const NXOAuth2ClientConnectionContextTokenRequest = @"tokenRequest";
NSString * const NXOAuth2ClientConnectionContextTokenRefresh = @"tokenRefresh";


@interface NXOAuth2Client ()
@property (nonatomic, readwrite, getter = isAuthenticating) BOOL authenticating;

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
    return [self initWithClientID:aClientId
                     clientSecret:aClientSecret
                     authorizeURL:anAuthorizeURL
                         tokenURL:aTokenURL
                      accessToken:nil
                       persistent:YES
                         delegate:aDelegate];
}

- (id)initWithClientID:(NSString *)aClientId
          clientSecret:(NSString *)aClientSecret
          authorizeURL:(NSURL *)anAuthorizeURL
              tokenURL:(NSURL *)aTokenURL
           accessToken:(NXOAuth2AccessToken *)anAccessToken
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<NXOAuth2ClientDelegate> *)aDelegate;
{
    return [self initWithClientID:aClientId
                     clientSecret:aClientSecret
                     authorizeURL:anAuthorizeURL
                         tokenURL:aTokenURL
                      accessToken:anAccessToken
                        tokenType:nil
                       persistent:shouldPersist
                         delegate:aDelegate];
}

- (id)initWithClientID:(NSString *)aClientId
          clientSecret:(NSString *)aClientSecret
          authorizeURL:(NSURL *)anAuthorizeURL
              tokenURL:(NSURL *)aTokenURL
           accessToken:(NXOAuth2AccessToken *)anAccessToken
             tokenType:(NSString *)aTokenType
            persistent:(BOOL)shouldPersist
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
        tokenType = [aTokenType copy];
        accessToken = anAccessToken;
        
        self.persistent = shouldPersist;
        self.delegate = aDelegate;
    }
    return self;
}

- (void)dealloc;
{
    [authConnection cancel];
}


#pragma mark Accessors

@synthesize clientId, clientSecret, tokenType;
@synthesize desiredScope, userAgent;
@synthesize delegate, persistent, accessToken, authenticating;

- (void)setPersistent:(BOOL)shouldPersist;
{
    if (persistent == shouldPersist) return;
    
    if (shouldPersist && accessToken) {
        [self.accessToken storeInDefaultKeychainWithServiceProviderName:[tokenURL host]];
    }
    
    if (persistent && !shouldPersist) {
        [accessToken removeFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
    }

    [self willChangeValueForKey:@"persistent"];
    persistent = shouldPersist;
    [self didChangeValueForKey:@"persistent"];
}

- (NXOAuth2AccessToken *)accessToken;
{
    if (accessToken) return accessToken;
    
    if (persistent) {
        accessToken = [NXOAuth2AccessToken tokenFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
        if (accessToken) {
            if ([delegate respondsToSelector:@selector(oauthClientDidGetAccessToken:)]) {
                [delegate oauthClientDidGetAccessToken:self];
            }
        }
        return accessToken;
    } else {
        return nil;
    }
}

- (void)setAccessToken:(NXOAuth2AccessToken *)value;
{
    if (self.accessToken == value) return;
    BOOL authorisationStatusChanged = ((accessToken == nil)    || (value == nil)); //They can't both be nil, see one line above. So they have to have changed from or to nil.
    
    if (!value) {
        [self.accessToken removeFromDefaultKeychainWithServiceProviderName:[tokenURL host]];
    }
    
    [self willChangeValueForKey:@"accessToken"];
    accessToken = value;
    [self didChangeValueForKey:@"accessToken"];
    
    if (persistent) {
        [accessToken storeInDefaultKeychainWithServiceProviderName:[tokenURL host]];
    }
    
    if (authorisationStatusChanged) {
        if (accessToken) {
            if ([delegate respondsToSelector:@selector(oauthClientDidGetAccessToken:)]) {
                [delegate oauthClientDidGetAccessToken:self];
            }
        } else {
            if ([delegate respondsToSelector:@selector(oauthClientDidLoseAccessToken:)]) {
                [delegate oauthClientDidLoseAccessToken:self];
            }
        }
    } else {
        if ([delegate respondsToSelector:@selector(oauthClientDidRefreshAccessToken:)]) {
            [delegate oauthClientDidRefreshAccessToken:self];
        }
    }
}

- (void)setDesiredScope:(NSSet *)aDesiredScope;
{
    if (desiredScope == aDesiredScope) {
        return;
    }
    
    desiredScope = [aDesiredScope copy];
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
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"code", @"response_type",
                                       clientId, @"client_id",
                                       [redirectURL absoluteString], @"redirect_uri",
                                       nil];
    
    if (self.desiredScope.count > 0) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    
    return [authorizeURL nxoauth2_URLByAddingParameters:parameters];
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
            if ([delegate respondsToSelector:@selector(oauthClient:didFailToGetAccessTokenWithError:)]) {
                [delegate oauthClient:self didFailToGetAccessTokenWithError:[NSError errorWithDomain:NXOAuth2ErrorDomain
                                                                                                code:errorCode
                                                                                            userInfo:userInfo]];
            }
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
    [authConnection cancel];  // just to be sure

    self.authenticating = YES;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"authorization_code", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       [redirectURL absoluteString], @"redirect_uri",
                                       authGrant, @"code",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
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
    [authConnection cancel];  // just to be sure

    self.authenticating = YES;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"password", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       username, @"username",
                                       password, @"password",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
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
        [authConnection cancel]; // not needed, but looks more clean to me :)
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           @"refresh_token", @"grant_type",
                                           clientId, @"client_id",
                                           clientSecret, @"client_secret",
                                           accessToken.refreshToken, @"refresh_token",
                                           nil];
        if (self.desiredScope) {
            [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
        }
        authConnection = [[NXOAuth2Connection alloc] initWithRequest:tokenRequest
                                                   requestParameters:parameters
                                                         oauthClient:self
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
        self.authenticating = NO;

        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NXOAuth2AccessToken *newToken = [NXOAuth2AccessToken tokenWithResponseBody:result tokenType:self.tokenType
                                         ];
        NSAssert(newToken != nil, @"invalid response?");
        
        [newToken restoreWithOldToken:self.accessToken];
        
        self.accessToken = newToken;
        
        for (NXOAuth2Connection *retryConnection in waitingConnections) {
            [retryConnection retry];
        }
        [waitingConnections removeAllObjects];
        
        authConnection = nil;
        
        refreshConnectionDidRetryCount = 0;    // reset
    }
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    NSString *body = [[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding];
    NSLog(@"oauthConnection Error: %@", body);
    
    
    if (connection == authConnection) {
        self.authenticating = NO;

        id context = connection.context;
        authConnection = nil;
        
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
                
                NSArray *failedConnections = [waitingConnections copy];
                [waitingConnections removeAllObjects];
                for (NXOAuth2Connection *connection in failedConnections) {
                    id<NXOAuth2ConnectionDelegate> connectionDelegate = connection.delegate;
                        if ([connectionDelegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
                        [connectionDelegate oauthConnection:connection didFailWithError:retryFailedError];
                    }
                }
            }
            
            if ([[error domain] isEqualToString:NXOAuth2HTTPErrorDomain]
                && error.code == 401) {
                self.accessToken = nil;        // reset the token since it got invalid
            }
            
            if ([delegate respondsToSelector:@selector(oauthClient:didFailToGetAccessTokenWithError:)]) {
                [delegate oauthClient:self didFailToGetAccessTokenWithError:error];
            }
        }
    }
}

@end
