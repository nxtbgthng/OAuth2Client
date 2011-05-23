//
//  NXOAuth2ConnectionDelegate.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NXOAuth2Constants.h"

@class NXOAuth2Connection;


@protocol NXOAuth2ConnectionDelegate <NSObject>
@optional

/*!
 *	The connection did receive a response.
 *
 *	This method is not called if the response was a 401 with an expired token & a refresh token.
 *	If so, then the token is refreshed & the connection will be automagically retried.
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didReceiveResponse:(NSURLResponse *)response;

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

/*!
 * The connection received a redirect response
 */
- (void)oauthConnection:(NXOAuth2Connection *)connection didReceiveRedirectToURL:(NSURL *)redirectURL;

/*!
 * Specifies Trust mode for the specific hostname. See NXOAuth2Constants.h for constants
 */
- (NXOAuth2TrustMode)oauthConnection:(NXOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;

/*!
 * Array of NSData objects that contains the trusted certificates for the hostname.
 */
- (NSArray *)oauthConnection:(NXOAuth2Connection *)connection trustedCertificatesDERDataForHostname:(NSString *)hostname;

@end