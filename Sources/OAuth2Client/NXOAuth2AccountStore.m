//
//  NXOAuth2AccountStore.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NXOAuth2Client.h"
#import "NXOAuth2AccountStoreDelegate.h"
#import "NXOAuth2Account.h"

#import "NXOAuth2AccountStore.h"

@interface NXOAuth2AccountStore ()
@property (nonatomic, readwrite, retain) NSMutableDictionary *pendingOAuthClients;
@property (nonatomic, readwrite, retain) NSMutableDictionary *accountsDict;

#pragma mark OAuthClient to AccountType Relation
- (NXOAuth2Client *)oauthClientForAccountType:(NSString *)accountType;
- (NSString *)accountTypeOfOAuthClient:(NXOAuth2Client *)oauthClient;
@end


@implementation NXOAuth2AccountStore

#pragma mark Lifecycle

+ (id)sharedStore;
{
    static NXOAuth2AccountStore *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [NXOAuth2AccountStore new];
    });
    return shared;
}

- (id)init;
{
    self = [super init];
    if (self) {
        self.pendingOAuthClients = [NSMutableDictionary dictionary];
        self.accountsDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Accessors

@synthesize pendingOAuthClients;
@synthesize accountsDict;

- (NSArray *)accounts;
{
    return [self.accountsDict allValues];
}

- (NSArray *)accountsWithAccountType:(NSString *)accountType;
{
    NSMutableArray *result = [NSMutableArray array];
    for (NXOAuth2Account *account in self.accounts) {
        if ([account.accountType isEqualToString:accountType]) {
            [result addObject:account];
        }
    }
    return result;
}

- (NXOAuth2Account *)accountWithIdentifier:(NSString *)identifier;
{
    return [self.accountsDict objectForKey:identifier];
}


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
{
    NXOAuth2Client *client = [self oauthClientForAccountType:accountType];
    [self.pendingOAuthClients setObject:client forKey:accountType];
    [client requestAccess];
}

- (void)removeAccount:(NXOAuth2Account *)account;
{
    [self.accountsDict removeObjectForKey:account.identifier];
}

#pragma mark Configuration

- (void)setConfiguration:(NSDictionary *)configuration
          forAccountType:(NSString *)accountType;
{
}


#pragma Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType
                                    block:(NXOAuth2TrustModeHandler)handler;
{
}

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType
                                              block:(NXOAuth2TrustedCertificatesHandler)handler;
{
}


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)URL;
{
    return NO;
}

- (BOOL)handleRedirectURL:(NSURL *)url forAccountWithType:(NSString *)accountType;
{
    NXOAuth2Client *client = [self.pendingOAuthClients objectForKey:accountType];
    if (client == nil) {
        client = [self oauthClientForAccountType:accountType];
    }
    return [client openRedirectURL:url];
}


#pragma mark OAuthClient to AccountType Relation

- (NXOAuth2Client *)oauthClientForAccountType:(NSString *)accountType;
{    
    id<NXOAuth2AccountStoreDelegate> appDelegate = (id<NXOAuth2AccountStoreDelegate>)[[UIApplication sharedApplication] delegate];
    
    NSString *clientID = [appDelegate clientIDForAccountsWithType:accountType];
    NSString *clientSecret = [appDelegate secretForAccountsWithType:accountType];
    NSURL *authorizeURL = [appDelegate authorizeURLForAccountsWithType:accountType];
    NSURL *tokenURL = [appDelegate tokenURLForAccountsWithType:accountType];
    
    NXOAuth2Client *client = [[[NXOAuth2Client alloc] initWithClientID:clientID
                                                          clientSecret:clientSecret
                                                          authorizeURL:authorizeURL
                                                              tokenURL:tokenURL
                                                              delegate:self] autorelease];
    client.persistent = NO;
    return client;
}

- (NSString *)accountTypeOfOAuthClient:(NXOAuth2Client *)oauthClient;
{
    NSSet *accountTypes = [self.pendingOAuthClients keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop){
        if ([obj isEqual:oauthClient]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    return [accountTypes anyObject];
}

#pragma mark NXOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;
{  
    id<NXOAuth2AccountStoreDelegate> appDelegate = (id<NXOAuth2AccountStoreDelegate>)[[UIApplication sharedApplication] delegate];
    NSURL *redirectURL = [appDelegate redirectURLForAccountsWithType:[self accountTypeOfOAuthClient:client]];
    [[UIApplication sharedApplication] openURL:[client authorizationURLWithRedirectURL:redirectURL]];
}

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
{
    NSString *accountType = [self accountTypeOfOAuthClient:client];
    [self.pendingOAuthClients removeObjectForKey:accountType];
    
    NXOAuth2Account *account = [[[NXOAuth2Account alloc] initAccountWithOAuthClient:client accountType:accountType] autorelease];
    [self.accountsDict setValue:account forKey:account.identifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountCreated object:account];
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    NSLog(@"%s %@", __FUNCTION__, error);
    [self.pendingOAuthClients removeObjectForKey:[self accountTypeOfOAuthClient:client]];
}

@end

