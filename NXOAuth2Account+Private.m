//
//  NXOAuth2Account+Private.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 19.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NSString+NXOAuth2.h"

#import "NXOAuth2Client.h"
#import "NXOAuth2Account.h"

#import "NXOAuth2Account+Private.h"

@implementation NXOAuth2Account (Private)

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)anOAuthClient accountType:(NSString *)anAccountType;
{
    self = [super init];
    if (self) {
        accountType = [anAccountType retain];
        oauthClient = [anOAuthClient retain];
        accessToken = [oauthClient.accessToken retain];
        oauthClient.delegate = self;
        identifier = [[NSString nxoauth2_stringWithUUID] retain];
    }
    return self;
}

@end
