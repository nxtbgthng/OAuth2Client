//
//  NXOAuth2Account.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2ClientDelegate.h"

@class NXOAuth2Client;

@interface NXOAuth2Account : NSObject <NXOAuth2ClientDelegate>

@property (nonatomic, readonly) NSString *accountType;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy) NSDictionary *userData;

@property (nonatomic, readonly) NXOAuth2Client *oauthClient;

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)oauthClient accountType:(NSString *)accountType;

@end
