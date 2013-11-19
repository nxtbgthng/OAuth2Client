//
//  NXOAuth2Account+Private.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 19.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import "NXOAuth2Account.h"

@interface NXOAuth2Account (Private)

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)oauthClient accountType:(NSString *)accountType;
- (id)initAccountWithAccessToken:(NXOAuth2AccessToken *)accessToken accountType:(NSString *)accountType;

@end
