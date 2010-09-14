//
//  NXOAuth2ClientDelegate.h
//  OAuth2Client
//
//  Created by Gernot Poetsch on 14.09.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NXOAuth2Client;

@protocol NXOAuth2ClientDelegate

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;

/*!
 * When this is called on the delegate, you are supposed to invoke the appropriate -authorize* method in the client.
 */
- (void)oauthClientNeedsAuthorization:(NXOAuth2Client *)client;
@end