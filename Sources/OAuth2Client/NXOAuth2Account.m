//
//  NXOAuth2Account.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NSString+NXOAuth2.h"

#import "NXOAuth2Client.h"
#import "NXOAuth2ClientDelegate.h"

#import "NXOAuth2Account.h"

@interface NXOAuth2Account () <NXOAuth2ClientDelegate>

@end


@implementation NXOAuth2Account

@synthesize accountType;
@synthesize identifier;
@synthesize userData;
@synthesize oauthClient;
@synthesize accessToken;

#pragma mark Lifecycle

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

- (void)dealloc;
{
    [accountType release];
    [oauthClient release];
    [accessToken release];
    [userData release];
    [identifier release];
    [super dealloc];
}

#pragma mark Accessors

- (NXOAuth2Client *)oauthClient;
{
    @synchronized (oauthClient) {
        if (oauthClient == nil) {
        // TODO: Create an oauth client with the marshaled token.
        }
    }
    return oauthClient;
}

- (void)setUserData:(id<NSObject,NSCoding,NSCopying>)someUserData;
{
    if (userData != someUserData) {
        [userData release]; userData = [someUserData retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeUserData
                                                            object:self];
    }
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
    [accessToken release];
    accessToken = [oauthClient.accessToken retain];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeAccessToken
                                                        object:self];
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    [accessToken release];
    accessToken = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeAccessToken
                                                        object:self];
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    [accessToken release];
    accessToken = nil;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error
                                                         forKey:kNXOAuth2AccountStoreError];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidFailToGetAccessToken
                                                        object:self
                                                      userInfo:userInfo];
}

@end
