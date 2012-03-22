//
//  NXOAuth2Connection.h
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

#import "NXOAuth2Constants.h"

@class NXOAuth2Client;
@protocol NXOAuth2ConnectionDelegate;


/*!
 *	The connection
 *	
 *	NXOAuth2Connection is a wrapper around NSURLConnection.
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



extern NSString * const NXOAuth2ConnectionDidStartNotification;
extern NSString * const NXOAuth2ConnectionDidEndNotification;


typedef void(^NXOAuth2ConnectionResponseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);
typedef void(^NXOAuth2ConnectionSendingProgressHandler)(unsigned long long bytesSend, unsigned long long bytesTotal);


@interface NXOAuth2Connection : NSObject {
@private
	NSURLConnection		*connection;
	NSMutableURLRequest	*request;
	NSURLResponse		*response;
	NSDictionary		*requestParameters;
	
	NSMutableData		*data;
    BOOL                savesData;
	
	id					context;
	NSDictionary		*userInfo;
	
	NXOAuth2Client		*client;
	
	NSObject<NXOAuth2ConnectionDelegate>	*delegate;	// assigned
    
    NXOAuth2ConnectionResponseHandler responseHandler;
    NXOAuth2ConnectionSendingProgressHandler sendingProgressHandler;
	
	BOOL				sendConnectionDidEndNotification;
    
#if (NXOAuth2ConnectionDebug)
    NSDate *startDate;
#endif
}

@property (assign) NSObject<NXOAuth2ConnectionDelegate>	*delegate;
@property (readonly) NSData *data;
@property (assign) BOOL savesData;
@property (readonly) long long expectedContentLength;
@property (readonly) NSURLResponse *response;
@property (readonly) NSInteger statusCode;
@property (retain) id context;
@property (retain) NSDictionary *userInfo;
@property (readonly) NXOAuth2Client *client;

- (id) initWithRequest:(NSMutableURLRequest *)request
     requestParameters:(NSDictionary *)requestParameters
           oauthClient:(NXOAuth2Client *)client
sendingProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)sendingProgressHandler
       responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler;

- (id)initWithRequest:(NSMutableURLRequest *)request
	requestParameters:(NSDictionary *)requestParameters
		  oauthClient:(NXOAuth2Client *)client
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)delegate;

- (void)cancel;

- (void)retry;

@end
