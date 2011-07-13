//
//  NXOAuth2Account.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Client.h"
#import "NSString+NXOAuth2.h"

#import "NXOAuth2Account.h"

@implementation NXOAuth2Account

@synthesize accountType;
@synthesize identifier;
@synthesize userData;
@synthesize oauthClient;

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)anOAuthClient accountType:(NSString *)anAccountType;
{
    self = [super init];
    if (self) {
        accountType = [anAccountType retain];
        oauthClient = [anOAuthClient retain];
        oauthClient.delegate = self;
        userData = [NSDictionary new];
        identifier = [[NSString nxoauth2_stringWithUUID] retain];
    }
    return self;
}

- (void)dealloc;
{
    [accountType release];
    [oauthClient release];
    [userData release];
    [identifier release];
    [super dealloc];
}

- (NXOAuth2Client *)oauthClient;
{
    @synchronized (oauthClient) {
        if (oauthClient == nil) {
        // TODO: Create an oauth client with the marshaled token.
        }
    }
    return oauthClient;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<NXOAuth2Account identifier:'%@' accountType:'%@' userData:%@>", self.identifier, self.accountType, self.userData];
}

#pragma mark NXOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    NSLog(@"%s", __FUNCTION__);
}

@end
