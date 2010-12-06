//
//  NXOAuth2Connection.h
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

#import "NXOAuth2Constants.h"

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

#ifndef NXOAuth2ConnectionDebug
#define NXOAuth2ConnectionDebug 0
#endif

@interface NXOAuth2Connection : NSObject {
@private
	NSURLConnection		*connection;
	NSURLRequest		*request;
	NSURLResponse		*response;
	
	NSMutableData		*data;
	
	id					context;
	NSDictionary		*userInfo;
    	
	NXOAuth2Client		*client;
	
	NSObject<NXOAuth2ConnectionDelegate>	*delegate;	// assigned
    
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
    void (^finish)(void);
    void (^fail)(NSError *error);
#endif
	
	BOOL				sentConnectionDidEndNotification;
    
#if (NXOAuth2ConnectionDebug)
    NSDate *startDate;
#endif
}

@property (assign) NSObject<NXOAuth2ConnectionDelegate>	*delegate;
@property (readonly) NSData *data;
@property (readonly) long long expectedContentLength;
@property (readonly) NSInteger statusCode;
@property (retain) id context;
@property (retain) NSDictionary *userInfo;

#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
- (id)initWithRequest:(NSURLRequest *)request
		  oauthClient:(NXOAuth2Client *)client
               finish:(void (^)(void))finishBlock 
                 fail:(void (^)(NSError *error))failBlock;
#endif


- (id)initWithRequest:(NSURLRequest *)request
		  oauthClient:(NXOAuth2Client *)client
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)delegate;

- (void)cancel;

- (void)retry;

@end
