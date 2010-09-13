//
//  NXOAuth2Client.h
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

#import <Foundation/Foundation.h>

#import "NXOAuth2ConnectionDelegate.h"


@class NXOAuth2Connection, NXOAuth2AccessToken;
@protocol NXOAuth2ClientAuthDelegate;

/*!
 * The OAuth 2.0 client
 * Only supports WebServer & Password flow at the moment
 *
 * - oauth2 draft 10 http://tools.ietf.org/html/draft-ietf-oauth-v2-10
 * - not thread save
 */

//TODO: Link to documentation

@interface NXOAuth2Client : NSObject <NXOAuth2ConnectionDelegate> {
@private
	NSString	*clientId;
	NSString	*clientSecret;
	
	// server information
	NSURL		*authorizeURL;
	NSURL		*tokenURL;
	
	// token exchange
	NXOAuth2Connection	*authConnection;
	NXOAuth2AccessToken	*accessToken;
	NSMutableArray	*retryConnectionsAfterTokenExchange;
	
	// delegates
	NSObject<NXOAuth2ClientAuthDelegate>*	authDelegate;	// assigned
}

@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *clientSecret;

@property (nonatomic, retain) NXOAuth2AccessToken	*accessToken;
@property (nonatomic, assign) NSObject<NXOAuth2ClientAuthDelegate>*	authDelegate;

/*!
 * Initializes the Client
 */
- (id)initWithClientID:(NSString *)clientId
		  clientSecret:(NSString *)clientSecret
		  authorizeURL:(NSURL *)authorizeURL
			  tokenURL:(NSURL *)tokenURL
		  authDelegate:(NSObject<NXOAuth2ClientAuthDelegate> *)authDelegate;


- (BOOL)openRedirectURL:(NSURL *)URL;

/*!
 * returns the URL to be opened to get access grant
 */
- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;	// web server flow

/*!
 * authenticate with username & password
 */
- (void)authorizeWithUsername:(NSString *)username password:(NSString *)password;	// user credentials flow


#pragma mark Public

- (void)requestAccess;

- (void)refreshAccessToken;
- (void)refreshAccessTokenAndRetryConnection:(NXOAuth2Connection *)retryConnection;
- (void)abortRetryOfConnection:(NXOAuth2Connection *)retryConnection;

@end