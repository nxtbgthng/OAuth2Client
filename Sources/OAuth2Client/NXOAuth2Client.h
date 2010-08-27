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
	
	// webserver flow
	NSURL		*redirectURL;
	
	// user credentials flow
	NSString	*username;
	NSString	*password;
	
	// grand & token exchange
	NXOAuth2Connection	*authConnection;
	NSString	*authGrand;
}

@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *clientSecret;


/*!
 * WebServer Flow
 */
- (id)initWithClientID:(NSString *)clientId
		  clientSecret:(NSString *)clientSecret
		   redirectURL:(NSURL *)redirectURL;

/*!
 * User credentials Flow
 */
- (id)initWithClientID:(NSString *)clientId
		  clientSecret:(NSString *)clientSecret
			  username:(NSString *)username
			  password:(NSString *)password;

@end
