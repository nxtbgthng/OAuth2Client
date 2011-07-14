//
//  NXOAuth2AccountStore.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NXOAuth2Client.h"
#import "NXOAuth2Account.h"

#import "NXOAuth2AccountStore.h"

@interface NXOAuth2AccountStore () <NXOAuth2ClientDelegate>
@property (nonatomic, readwrite, retain) NSMutableDictionary *pendingOAuthClients;
@property (nonatomic, readwrite, retain) NSMutableDictionary *accountsDict;

@property (nonatomic, readwrite, retain) NSMutableDictionary *configurations;
@property (nonatomic, readwrite, retain) NSMutableDictionary *trustModeHandler;
@property (nonatomic, readwrite, retain) NSMutableDictionary *trustedCertificatesHandler;

#pragma mark OAuthClient to AccountType Relation
- (NXOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
- (NSString *)accountTypeOfPendingOAuthClient:(NXOAuth2Client *)oauthClient;

@property (nonatomic, assign) id accountUserDataObserver;
@property (nonatomic, assign) id accountAccessTokenObserver;
@property (nonatomic, assign) id accountFailToGetAccessTokenObserver;
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
        self.configurations = [NSMutableDictionary dictionary];
        
        self.accountUserDataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeUserData
                                                                                 object:nil
                                                                                  queue:nil
                                                                             usingBlock:^(NSNotification *notification){
                                                                                 NSLog(@"Account %@ did change user data.", notification.object);
                                                                             }];
        
        self.accountAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeAccessToken
                                                                                         object:nil
                                                                                          queue:nil
                                                                                     usingBlock:^(NSNotification *notification){
                                                                                         NSLog(@"Account %@ did change access token.", notification.object);
                                                                                     }];
        
        self.accountFailToGetAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidFailToGetAccessToken
                                                                                         object:nil
                                                                                          queue:nil
                                                                                     usingBlock:^(NSNotification *notification){
                                                                                         NSLog(@"Account %@ did fail to get access token.", notification.object);
                                                                                     }];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountUserDataObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountAccessTokenObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountFailToGetAccessTokenObserver];
    [super dealloc];
}

#pragma mark Accessors

@synthesize pendingOAuthClients;
@synthesize accountsDict;

@synthesize configurations;
@synthesize trustModeHandler;
@synthesize trustedCertificatesHandler;

@synthesize accountUserDataObserver;
@synthesize accountAccessTokenObserver;
@synthesize accountFailToGetAccessTokenObserver;

- (NSArray *)accounts;
{
    @synchronized (self.accountsDict) {
        return [self.accountsDict allValues];
    }
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
    @synchronized (self.accountsDict) {
        return [self.accountsDict objectForKey:identifier];
    }
}


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
{
    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client requestAccess];
}

- (void)removeAccount:(NXOAuth2Account *)account;
{
    @synchronized (self.accountsDict) {
        [self.accountsDict removeObjectForKey:account.identifier];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountRemoved object:account];
}

#pragma mark Configuration

- (void)setConfiguration:(NSDictionary *)configuration
          forAccountType:(NSString *)accountType;
{
    // TODO: Check if configuration is valid
    @synchronized (self.configurations) {
        [self.configurations setObject:configuration forKey:accountType];
    }
}


#pragma Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType
                                    block:(NXOAuth2TrustModeHandler)handler;
{
    @synchronized (self.trustModeHandler) {
        [self.trustModeHandler setObject:[[handler copy] autorelease] forKey:accountType];
    }
}

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType
                                              block:(NXOAuth2TrustedCertificatesHandler)handler;
{
    @synchronized (self.trustedCertificatesHandler) {
        [self.trustedCertificatesHandler setObject:[[handler copy] autorelease] forKey:accountType];
    }
}


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)aURL;
{
    NSSet *accountTypes;
    @synchronized (self.configurations) {
        accountTypes = [self.configurations keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
            NSDictionary *configuration = obj;
            NSURL *redirectURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationRedirectURL];
            if ( [[aURL absoluteString] hasPrefix:[redirectURL absoluteString]]) {
                return YES;
            } else {
                return NO;
            }
        }];
    }
    
    for (NSString *accountType in accountTypes) {
        NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
        if ([client openRedirectURL:aURL]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark OAuthClient to AccountType Relation

- (NXOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
{
    @synchronized (self.pendingOAuthClients) {
        NXOAuth2Client *client = [self.pendingOAuthClients objectForKey:accountType];
        
        if (!client) {
            NSDictionary *configuration;
            @synchronized (self.configurations) {
                configuration = [self.configurations objectForKey:accountType];
            }
            
            NSString *clientID = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret];
            NSURL *authorizeURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL];
            
            client = [[[NXOAuth2Client alloc] initWithClientID:clientID
                                                  clientSecret:clientSecret
                                                  authorizeURL:authorizeURL
                                                      tokenURL:tokenURL
                                                      delegate:self] autorelease];
            client.persistent = NO;
            
            [self.pendingOAuthClients setObject:client forKey:accountType];
        }
        return client;    
    }
}

- (NSString *)accountTypeOfPendingOAuthClient:(NXOAuth2Client *)oauthClient;
{
    @synchronized (self.pendingOAuthClients) {
        NSSet *accountTypes = [self.pendingOAuthClients keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop){
            if ([obj isEqual:oauthClient]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        return [accountTypes anyObject];
    }
}

#pragma mark NXOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;
{  
    NSString *accountType = [self accountTypeOfPendingOAuthClient:client];
    
    NSDictionary *configuration;
    @synchronized (self.configurations) {
        configuration = [self.configurations objectForKey:accountType];
    }
    
    NSURL *redirectURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationRedirectURL];
    
    // TODO: Should the URL be opend via a method provided by the user?
    [[UIApplication sharedApplication] openURL:[client authorizationURLWithRedirectURL:redirectURL]];
}

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
{
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }
    
    NXOAuth2Account *account = [[[NXOAuth2Account alloc] initAccountWithOAuthClient:client accountType:accountType] autorelease];
    @synchronized (self.accountsDict) {
        [self.accountsDict setValue:account forKey:account.identifier];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountCreated object:account];
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    // This delegate method should never be called because the account store
    // does not act as an delegate for established connections.
    
    NSLog(@"Account store did lose access token for client: %@", client);
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    NSLog(@"Account store did fail to get access token with error: %@", error);
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              accountType, kNXOAuth2AccountStoreAccountType,
                              error, kNXOAuth2AccountStoreError, nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreFailToGetAccessToken
                                                        object:self
                                                      userInfo:userInfo];
}

@end

