//
//  NXOAuth2ClientDelegate.h
//  OAuth2Client
//
//  Created by Gernot Poetsch on 14.09.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//


#import "NXOAuth2Constants.h"

@class NXOAuth2Client;

@protocol NXOAuth2ClientDelegate

@required
/*!
 * When this is called on the delegate, you are supposed to invoke the appropriate authentication method in the client.
 */
- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;

@optional
- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;


/*!
 * Specifies Trust mode for the specific hostname. See NXOAuth2Constants.h for constants
 */
- (NXOAuth2TrustMode)oauthClient:(NXOAuth2Client *)client trustModeForTokenRequestOnHostname:(NSString *)hostname;

/*!
 * Return the trusted certificates in their DER representation as NSData objects.
 */
- (NSArray *)oauthClient:(NXOAuth2Client *)client trustedCertificatesDERDataForTokenRequestOnHostname:(NSString *)hostname;

@end