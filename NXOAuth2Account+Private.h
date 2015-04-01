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

#import <OAuth2Client/NXOAuth2Account.h>

@protocol NXApplication;

@interface NXOAuth2Account (Private)

@property (nonatomic, readonly) id<NXApplication> application;

- (instancetype)initAccountWithOAuthClient:(NXOAuth2Client *)oauthClient
                               accountType:(NSString *)accountType
                               application:(id<NXApplication>)app;

- (instancetype)initAccountWithAccessToken:(NXOAuth2AccessToken *)accessToken
                               accountType:(NSString *)accountType
                               application:(id<NXApplication>)app /*NS_DESIGNATED_INITIALIZER*/ NS_REQUIRES_SUPER;

@end
