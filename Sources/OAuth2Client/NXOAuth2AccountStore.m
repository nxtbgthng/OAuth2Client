//
//  NXOAuth2AccountStore.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif


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


#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
+ (NSDictionary *)accountsFromDefaultKeychain;
+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
+ (void)removeFromDefaultKeychain;

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
        self.accountsDict = [NSMutableDictionary dictionaryWithDictionary:[NXOAuth2AccountStore accountsFromDefaultKeychain]];
        self.configurations = [NSMutableDictionary dictionary];
        
        self.accountUserDataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeUserData
                                                                                 object:nil
                                                                                  queue:nil
                                                                             usingBlock:^(NSNotification *notification){
//                                                                                 NSLog(@"Account %@ did change user data.", notification.object);
                                                                                 @synchronized (self.accountsDict) {
                                                                                     [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
                                                                                 }
                                                                             }];
        
        self.accountAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeAccessToken
                                                                                         object:nil
                                                                                          queue:nil
                                                                                     usingBlock:^(NSNotification *notification){
//                                                                                         NSLog(@"Account %@ did change access token.", notification.object);
                                                                                     }];
        
        self.accountFailToGetAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidFailToGetAccessToken
                                                                                         object:nil
                                                                                          queue:nil
                                                                                     usingBlock:^(NSNotification *notification){
//                                                                                         NSLog(@"Account %@ did fail to get access token.", notification.object);
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
    NSArray *result = nil;
    @synchronized (self.accountsDict) {
        result = [self.accountsDict allValues];
    }
    return result;
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
    NXOAuth2Account *result = nil;
    @synchronized (self.accountsDict) {
        result = [self.accountsDict objectForKey:identifier];
    }
    return result;
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

- (NSDictionary *)configurationForAccountType:(NSString *)accountType;
{
    NSDictionary *result = nil;
    @synchronized (self.configurations) {
       result = [self.configurations objectForKey:accountType];
    }
    return result;
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
    NXOAuth2Client *client = nil;
    @synchronized (self.pendingOAuthClients) {
        client = [self.pendingOAuthClients objectForKey:accountType];
        
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
    }
    return client; 
}

- (NSString *)accountTypeOfPendingOAuthClient:(NXOAuth2Client *)oauthClient;
{
    NSString *result = nil;
    @synchronized (self.pendingOAuthClients) {
        NSSet *accountTypes = [self.pendingOAuthClients keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop){
            if ([obj isEqual:oauthClient]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        result = [accountTypes anyObject];
    }
    return result;
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
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] openURL:[client authorizationURLWithRedirectURL:redirectURL]];
#else
    [[NSWorkspace sharedWorkspace] openURL:[client authorizationURLWithRedirectURL:redirectURL]];
#endif
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
        [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
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

#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
{
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
	return [NSString stringWithFormat:@"%@::NXOAuth2AccountStore", appName];
}

#if TARGET_OS_IPHONE

#else

+ (NSDictionary *)accountsFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
    
	SecKeychainItemRef item = nil;
	OSStatus err = SecKeychainFindGenericPassword(NULL,
												  strlen([serviceName UTF8String]),
												  [serviceName UTF8String],
												  0,
												  NULL,
												  NULL,
												  NULL,
												  &item);
	if (err != noErr) {
		NSAssert1(err == errSecItemNotFound, @"Unexpected error while fetching accounts from keychain: %d", err);
		return nil;
	}
    
    // from Advanced Mac OS X Programming, ch. 16
    UInt32 length;
    char *password;
	NSData *result = nil;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
    
    list.count = 4;
    list.attr = attributes;
    
    err = SecKeychainItemCopyContent(item, NULL, &list, &length, (void **)&password);
    if (err == noErr) {
        if (password != NULL) {
			result = [NSData dataWithBytes:password length:length];
        }
        SecKeychainItemFreeContent(&list, password);
    } else {
		// TODO find out why this always works in i386 and always fails on ppc
		NSLog(@"Error from SecKeychainItemCopyContent: %d", err);
        return nil;
    }
    CFRelease(item);
	return [NSKeyedUnarchiver unarchiveObjectWithData:result];
}

+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
{
    [self removeFromDefaultKeychain];
 
    NSString *serviceName = [self keychainServiceName];
    
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accounts];
	
	OSStatus __attribute__((unused))err = SecKeychainAddGenericPassword(NULL,
																		strlen([serviceName UTF8String]),
																		[serviceName UTF8String],
																		0,
																		NULL,
																		[data length],
																		[data bytes],
																		NULL);
    
	NSAssert1(err == noErr, @"Error while storing accounts in keychain: %d", err);
}

+ (void)removeFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
	
    SecKeychainItemRef item = nil;
	OSStatus err = SecKeychainFindGenericPassword(NULL,
												  strlen([serviceName UTF8String]),
												  [serviceName UTF8String],
												  0,
												  NULL,
												  NULL,
												  NULL,
												  &item);
	NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting accounts from keychain: %d", err);
	if (err == noErr) {
		err = SecKeychainItemDelete(item);
	}
	if (item) {
		CFRelease(item);	
	}
	NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting accounts from keychain: %d", err);
}

#endif

@end

