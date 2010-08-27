/*
 *  NXOAuth2ConnectionDelegate.h
 *  OAuth2Client
 *
 *  Created by Ullrich Schäfer on 27.08.10.
 *  Copyright 2010 nxtbgthng. All rights reserved.
 *
 */


@class NXOAuth2Connection;


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