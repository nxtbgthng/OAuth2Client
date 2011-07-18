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
#import "NXOAuth2AccountStore.h"

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
            
            NSDictionary *configuration = [[NXOAuth2AccountStore sharedStore] configurationForAccountType:self.accountType];
            
            NSString *clientID = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret];
            NSURL *authorizeURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL];
            
            oauthClient = [[NXOAuth2Client alloc] initWithClientID:clientID
                                                      clientSecret:clientSecret
                                                      authorizeURL:authorizeURL
                                                          tokenURL:tokenURL
                                                       accessToken:self.accessToken
                                                        persistent:NO
                                                          delegate:self];
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
    // TODO: Will this delegate method be called if a client is already connected?
    
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
    // TODO: In which situations will this method be called on an already authenticated client?
    
    [accessToken release];
    accessToken = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeAccessToken
                                                        object:self];
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    // TODO: In which situations will this method be called on an already authenticated client?
    
    [accessToken release];
    accessToken = nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error
                                                         forKey:kNXOAuth2AccountStoreError];
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidFailToGetAccessToken
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark NXOAuth2TrustDelegate

-(NXOAuth2TrustMode)connection:(NXOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;
{
    NXOAuth2TrustModeHandler handler = [[NXOAuth2AccountStore sharedStore] trustModeHandlerForAccountType:self.accountType];
    if (handler) {
        return handler(connection, hostname);
    } else {
        return NXOAuth2TrustModeSystem;
    }
}

-(NSArray *)connection:(NXOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;
{
    NXOAuth2TrustedCertificatesHandler handler = [[NXOAuth2AccountStore sharedStore] trustedCertificatesHandlerForAccountType:self.accountType];
    return handler(hostname);
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:identifier forKey:@"identifier"];
	[aCoder encodeObject:accessToken forKey:@"accessToken"];
	[aCoder encodeObject:accountType forKey:@"accountType"];
    [aCoder encodeObject:userData forKey:@"userData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init]) {
		identifier = [[aDecoder decodeObjectForKey:@"identifier"] copy];
		accessToken = [[aDecoder decodeObjectForKey:@"accessToken"] retain];
		accountType = [[aDecoder decodeObjectForKey:@"accountType"] copy];
        userData = [[aDecoder decodeObjectForKey:@"userData"] copy];
	}
	return self;
}

@end
