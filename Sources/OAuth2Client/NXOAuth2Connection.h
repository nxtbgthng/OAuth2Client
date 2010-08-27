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
	
	NSMutableData		*data;
	NSUInteger	expectedContentLength;
	NSInteger	statusCode;
	
	id context;
	
	NXOAuth2Client		*client;
	
	NSObject<NXOAuth2ConnectionDelegate>	*delegate;	// assigned
}

@property (readonly) NSData *data;
@property (readonly) NSUInteger expectedContentLength;
@property (readonly) NSInteger statusCode;
@property (retain) id context;

- (id)initWithRequest:(NSURLRequest *)request
		  oauthClient:(NXOAuth2Client *)client
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)delegate;

@end


@protocol NXOAuth2ConnectionDelegate
@optional

/*!
 *	The connection did finish and recieved the whole data.
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;

/*!
 *	The connection did fail with an error
 *	
 *	The domain of the error is NXOAuth2ErrorDomain.
 *	Check the error code to see if it's been an HTTP error (NXOAuth2HTTPErrorCode). If so you can get the original error from the userInfo with the key NXOAuth2HTTPErrorKey
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;

/*!
 *	The connection recieved a new chunk of bytes.
 *	
 *	Note: use connection.data.length and connection.expectedContentLength to get the overall progress
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didReceiveData:(NSData *)data;

/*!
 *	The connection did send new data
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;
@end