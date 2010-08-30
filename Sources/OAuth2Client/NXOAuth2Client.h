//
//  NXOAuth2Client.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2ConnectionDelegate.h"


@class NXOAuth2Connection;
@protocol NXOAuth2ClientAuthDelegate;

/*!
 * The OAuth 2.0 client
 * Only supports WebServer & Password flow at the moment
 *
 * - oauth2 draft 10 http://tools.ietf.org/html/draft-ietf-oauth-v2-10
 * - not thread save
 */
@interface NXOAuth2Client : NSObject <NXOAuth2ConnectionDelegate> {
@private
	NSString	*clientId;
	NSString	*clientSecret;
	
	// server information
	NSURL		*authorizeURL;
	NSURL		*tokenURL;
	
	// webserver flow
	NSURL		*redirectURL;
	
	// user credentials flow
	NSString	*username;
	NSString	*password;
	
	// grand & token exchange
	NXOAuth2Connection	*authConnection;
	NSString	*authGrand;
	
	// delegates
	NSObject<NXOAuth2ClientAuthDelegate>*	authDelegate;
}

@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *clientSecret;


#pragma mark WebServer Flow

/*!
 * Initializes the Client
 */
- (id)initWithClientID:(NSString *)clientId
		  clientSecret:(NSString *)clientSecret
		  authorizeURL:(NSURL *)authorizeURL
			  tokenURL:(NSURL *)tokenURL
		   redirectURL:(NSURL *)redirectURL;

- (BOOL)openURL:(NSURL *)URL;


#pragma mark User credentials Flow

/*!
 * Initializes the Client
 */
- (id)initWithClientID:(NSString *)clientId
		  clientSecret:(NSString *)clientSecret
		  authorizeURL:(NSURL *)authorizeURL
			  tokenURL:(NSURL *)tokenURL
			  username:(NSString *)username
			  password:(NSString *)password;

@end


@protocol NXOAuth2ClientAuthDelegate
- (void)oauthClient:(NXOAuth2Client *)client requestedAuthorizationWithURL:(NSURL *)authorizationURL;
@end