/*
 *  NXOAuth2ClientAuthDelegate.h
 *  OAuth2Client
 *
 *  Created by Ullrich Schäfer on 13.09.10.
 *  Copyright 2010 nxtbgthng. All rights reserved. 
 *  Licenced under the new BSD-licence.
 *  See README.md in this reprository for 
 *  the full licence.
 *
 */


@class NSOAuth2Client;

@protocol NXOAuth2ClientAuthDelegate
- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;

/*!
 * use one of the -autherize* methods
 */
- (void)oauthClientRequestedAuthorization:(NXOAuth2Client *)client;
@end