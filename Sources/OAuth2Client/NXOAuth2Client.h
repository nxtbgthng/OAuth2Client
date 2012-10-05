//
//  NXOAuth2Client.h
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

#import <Foundation/Foundation.h>

#import "NXOAuth2ClientDelegate.h"
#import "NXOAuth2ConnectionDelegate.h"

extern NSString * const NXOAuth2ClientConnectionContextTokenRequest;
extern NSString * const NXOAuth2ClientConnectionContextTokenRefresh;

@class NXOAuth2Connection, NXOAuth2AccessToken;

/*!
 * The OAuth 2.0 client
 * Only supports WebServer & Password flow at the moment
 *
 * - oauth2 draft 10 http://tools.ietf.org/html/draft-ietf-oauth-v2-10
 * - not thread save
 */

//TODO: Link to documentation

@interface NXOAuth2Client : NSObject <NXOAuth2ConnectionDelegate> {
@protected
    BOOL authenticating;
    BOOL persistent;

    NSString    *clientId;
    NSString    *clientSecret;
    
    NSSet       *desiredScope;
    NSString    *userAgent;
    NSString    *assertion;
    
    // server information
    NSURL        *authorizeURL;
    NSURL        *tokenURL;
    
    // token exchange
    NXOAuth2Connection    *authConnection;
    NXOAuth2AccessToken    *accessToken;
    NSMutableArray    *waitingConnections; //for connections that are waiting for successful authorisation
    NSInteger        refreshConnectionDidRetryCount;
    
    // delegates
    NSObject<NXOAuth2ClientDelegate>*    __unsafe_unretained delegate;    // assigned
}

@property (nonatomic, readonly, getter = isAuthenticating) BOOL authenticating;

@property (nonatomic, copy, readonly) NSString *clientId;
@property (nonatomic, copy, readonly) NSString *clientSecret;

@property (nonatomic, copy) NSSet *desiredScope;
@property (nonatomic, copy) NSString *userAgent;

@property (nonatomic, strong) NXOAuth2AccessToken    *accessToken;
@property (nonatomic, unsafe_unretained) NSObject<NXOAuth2ClientDelegate>*    delegate;

/*!
 * If set to NO, the access token is not stored any keychain, will be removed if it was.
 * Defaults to YES
 */
@property (nonatomic, assign, readwrite, getter=isPersistent) BOOL persistent;

/*!
 * Initializes the Client
 */
- (id)initWithClientID:(NSString *)clientId
          clientSecret:(NSString *)clientSecret
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL
              delegate:(NSObject<NXOAuth2ClientDelegate> *)delegate;

- (id)initWithClientID:(NSString *)clientId
          clientSecret:(NSString *)clientSecret
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL
           accessToken:(NXOAuth2AccessToken *)accessToken
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<NXOAuth2ClientDelegate> *)delegate;

- (BOOL)openRedirectURL:(NSURL *)URL;


#pragma mark Authorisation Methods

/*---------------------------------*
 * Use ONE of the following flows: *
 *---------------------------------*/

/*!
 * Authenticate usind a web URL (Web Server Flow)
 * returns the URL to be opened to get access grant
 */
- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;

/*!
 * Authenticate with username & password (User Credentials Flow)
 */
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;

#pragma mark Public

- (void)requestAccess;

- (void)refreshAccessToken;
- (void)refreshAccessTokenAndRetryConnection:(NXOAuth2Connection *)retryConnection;

@end