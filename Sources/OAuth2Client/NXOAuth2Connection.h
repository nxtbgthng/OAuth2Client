//
//  NXOAuth2Connection.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2Constants.h"
#import "NXOAuth2PostBodyStreamMonitorDelegate.h"

@class NXOAuth2Client;
@protocol NXOAuth2ConnectionDelegate;


/*!
 *	The connection
 *	
 *	NXOAuth2Connection is a wrapper around NXURLConnection.
 *	It's main purpose is to simplify the delegates & to provide a context
 *	ivar that can be used to put a connection object in a certain context.
 *	The context may be compared to a tag.
 *	
 *	NXOAuth2Connection only provides asynchronous connections as synchronous
 *	connections are strongly discouraged.
 *	
 *	The connection works together with the OAuth2 Client to sign a request
 *	before sending it. If no client is passed in the connection will sent
 *	unsigned requests.
 */
@interface NXOAuth2Connection : NSObject <NXOAuth2PostBodyStreamMonitorDelegate> {
@private
	NSURLConnection		*connection;
	NSURLRequest		*request;
	NSURLResponse		*response;
	
	NSMutableData		*data;
	
	id					context;
	NSDictionary		*userInfo;
	
	NXOAuth2Client		*client;
	
	NSObject<NXOAuth2ConnectionDelegate>	*delegate;	// assigned
}

@property (readonly) NSData *data;
@property (readonly) long long expectedContentLength;
@property (readonly) NSInteger statusCode;
@property (retain) id context;
@property (retain) NSDictionary *userInfo;

- (id)initWithRequest:(NSURLRequest *)request
		  oauthClient:(NXOAuth2Client *)client
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)delegate;

- (void)cancel;

- (void)retry;

@end
