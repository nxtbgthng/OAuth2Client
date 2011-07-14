//
//  NXOAuth2Account.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NXOAuth2Client;
@class NXOAuth2AccessToken;

@interface NXOAuth2Account : NSObject 

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)oauthClient accountType:(NSString *)accountType;

#pragma mark Accessors

@property (nonatomic, readonly) NSString *accountType;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy) id <NSObject, NSCoding, NSCopying> userData;

@property (nonatomic, readonly) NXOAuth2Client *oauthClient;
@property (nonatomic, readonly) NXOAuth2AccessToken *accessToken;

@end
