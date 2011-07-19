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
#import "NXOAuth2Connection.h"
#import "NXOAuth2Account.h"
#import "NXOAuth2Account+Private.h"

#import "NXOAuth2AccountStore.h"

@interface NXOAuth2AccountStore () <NXOAuth2ClientDelegate>
@property (nonatomic, readwrite, retain) NSMutableDictionary *pendingOAuthClients;
@property (nonatomic, readwrite, retain) NSMutableDictionary *accountsDict;

@property (nonatomic, readwrite, retain) NSMutableDictionary *configurations;
@property (nonatomic, readwrite, retain) NSMutableDictionary *trustModeHandler;
@property (nonatomic, readwrite, retain) NSMutableDictionary *trustedCertificatesHandler;
@property (nonatomic, readwrite, retain) NSMutableDictionary *preparedAuthorizationURLHandler;

#pragma mark OAuthClient to AccountType Relation
- (NXOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
- (NSString *)accountTypeOfPendingOAuthClient:(NXOAuth2Client *)oauthClient;

@property (nonatomic, assign) id accountDidChangeUserDataObserver;
@property (nonatomic, assign) id accountDidChangeAccessTokenObserver;
@property (nonatomic, assign) id accountDidLoseAccessTokenObserver;
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
        self.trustModeHandler = [NSMutableDictionary dictionary];
        self.trustedCertificatesHandler = [NSMutableDictionary dictionary];
        self.preparedAuthorizationURLHandler = [NSMutableDictionary dictionary];
        
        self.accountDidChangeUserDataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeUserData
                                                                                                  object:nil
                                                                                                   queue:nil
                                                                                              usingBlock:^(NSNotification *notification){
                                                                                                  @synchronized (self.accountsDict) {
                                                                                                      // The user data of an account has been changed.
                                                                                                      // Save all accounts in the default keychain.
                                                                                                      [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
                                                                                                  }
                                                                                              }];
        
        self.accountDidChangeAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeAccessToken
                                                                                                     object:nil
                                                                                                      queue:nil
                                                                                                 usingBlock:^(NSNotification *notification){
                                                                                                     @synchronized (self.accountsDict) {
                                                                                                         // An access token of an account has been changed.
                                                                                                         // Save all accounts in the default keychain.
                                                                                                         [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
                                                                                                     }
                                                                                                 }];
        
        self.accountDidLoseAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidLoseAccessToken
                                                                                                   object:nil
                                                                                                    queue:nil
                                                                                               usingBlock:^(NSNotification *notification){
                                                                                                   // Remove accounts from the account store if there
                                                                                                   // access token could not be refreshed.
                                                                                                   // These accounts can't be used anymore.
                                                                                                   NSLog(@"Removing account from store because it lost its access token. - %@", notification.object);
                                                                                                   [self removeAccount:notification.object];
                                                                                               }];
        
        self.accountFailToGetAccessTokenObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidFailToGetAccessToken
                                                                                                     object:nil
                                                                                                      queue:nil
                                                                                                 usingBlock:^(NSNotification *notification){
                                                                                                     // TODO: How should this kind of error be handled?
                                                                                                 }];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountDidChangeUserDataObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountDidChangeAccessTokenObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountDidLoseAccessTokenObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.accountFailToGetAccessTokenObserver];
    
    [pendingOAuthClients release];
    [accountsDict release];
    [configurations release];
    [trustModeHandler release];
    [trustedCertificatesHandler release];
    
    [super dealloc];
}

#pragma mark Accessors

@synthesize pendingOAuthClients;
@synthesize accountsDict;

@synthesize configurations;
@synthesize trustModeHandler;
@synthesize trustedCertificatesHandler;

@synthesize accountDidChangeUserDataObserver;
@synthesize accountDidChangeAccessTokenObserver;
@synthesize accountDidLoseAccessTokenObserver;
@synthesize accountFailToGetAccessTokenObserver;
@synthesize preparedAuthorizationURLHandler;

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

- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
{
    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithUsername:username password:password];
}

- (void)removeAccount:(NXOAuth2Account *)account;
{
    @synchronized (self.accountsDict) {
        [self.accountsDict removeObjectForKey:account.identifier];
        [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountRemoved object:account];
}

#pragma mark Configuration

- (void)setConfiguration:(NSDictionary *)configuration
          forAccountType:(NSString *)accountType;
{
    NSAssert([configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID], @"Missing OAuth2 client ID for account type '%@'.", accountType);
    NSAssert([configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret], @"Missing OAuth2 client secret for account type '%@'.", accountType);
    NSAssert([configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL], @"Missing OAuth2 authorize URL for account type '%@'.", accountType);
    NSAssert([configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL], @"Missing OAuth2 token URL for account type '%@'.", accountType);
    
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

#pragma mark Prepared Authorization URL Handler

- (void)setPreparedAuthorizationURLHandlerForAccountType:(NSString *)accountType block:(NXOAuth2PreparedAuthorizationURLHandler)handler;
{
    @synchronized (preparedAuthorizationURLHandler) {
        [self.preparedAuthorizationURLHandler setObject:[[handler copy] autorelease] forKey:accountType];
    }
}

- (NXOAuth2PreparedAuthorizationURLHandler)preparedAuthorizationURLHandlerForAccountType:(NSString *)accountType;
{
    return [self.preparedAuthorizationURLHandler objectForKey:accountType];
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

- (NXOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;
{
    return [self.trustModeHandler objectForKey:accountType];
}

- (NXOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;
{
    NXOAuth2TrustedCertificatesHandler handler = [self.trustedCertificatesHandler objectForKey:accountType];
    NSAssert(handler, @"You need to provied a NXOAuth2TrustedCertificatesHandler for account type '%@' because you are using 'NXOAuth2TrustModeSpecificCertificate' as trust mode for that account type.");
    return handler;
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
    NSURL *preparedURL = [client authorizationURLWithRedirectURL:redirectURL];
    
    NXOAuth2PreparedAuthorizationURLHandler handler = [self preparedAuthorizationURLHandlerForAccountType:accountType];
    
    if (handler) {
        handler(preparedURL);
    } else {
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] openURL:preparedURL];
#else
        [[NSWorkspace sharedWorkspace] openURL:preparedURL];
#endif
    }
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreDidFailToRequestAccess
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark NXOAuth2TrustDelegate

-(NXOAuth2TrustMode)connection:(NXOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;
{
    NSString *accountType = [self accountTypeOfPendingOAuthClient:connection.client];
    NXOAuth2TrustModeHandler handler = [self trustModeHandlerForAccountType:accountType];
    if (handler) {
        return handler(connection, hostname);
    } else {
        return NXOAuth2TrustModeSystem;
    }
}

-(NSArray *)connection:(NXOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;
{
    NSString *accountType = [self accountTypeOfPendingOAuthClient:connection.client];
    NXOAuth2TrustedCertificatesHandler handler = [self trustedCertificatesHandlerForAccountType:accountType];
    return handler(hostname);
}


#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
{
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
	return [NSString stringWithFormat:@"%@::NXOAuth2AccountStore", appName];
}

#if TARGET_OS_IPHONE

+ (NSDictionary *)accountsFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
    
    NSDictionary *result = nil;
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   kCFBooleanTrue, kSecReturnAttributes,
						   nil];
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
	[result autorelease];
	
	if (status != noErr) {
		NSAssert1(status == errSecItemNotFound, @"Unexpected error while fetching accounts from keychain: %d", status);
		return nil;
	}
	
	return [NSKeyedUnarchiver unarchiveObjectWithData:[result objectForKey:(NSString *)kSecAttrGeneric]];
}

+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
{
    [self removeFromDefaultKeychain];
 
    NSString *serviceName = [self keychainServiceName];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accounts];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   @"OAuth 2 Account Store", kSecAttrLabel,
						   data, kSecAttrGeneric,
						   nil];
	OSStatus __attribute__((unused)) err = SecItemAdd((CFDictionaryRef)query, NULL);
	NSAssert1(err == noErr, @"Error while adding token to keychain: %d", err);
}

+ (void)removeFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   nil];
	OSStatus __attribute__((unused)) err = SecItemDelete((CFDictionaryRef)query);
	NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting token from keychain: %d", err);

}

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

