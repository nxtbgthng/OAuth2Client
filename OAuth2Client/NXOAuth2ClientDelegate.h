//
//  NXOAuth2ClientDelegate.h
//  OAuth2Client
//
//  Created by Gernot Poetsch on 14.09.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//


#import <OAuth2Client/NXOAuth2TrustDelegate.h>

@class NXOAuth2Client;

@protocol NXOAuth2ClientDelegate <NXOAuth2TrustDelegate>

@required
/*!
 * When this is called on the delegate, you are supposed to invoke the appropriate authentication method in the client.
 */
- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;

@optional
- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
- (void)oauthClientDidRefreshAccessToken:(NXOAuth2Client *)client;
- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;

@end