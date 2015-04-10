//
//  NXOAuth2AccountStore.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//



#import "NXOAuth2Client.h"
#import "NXOAuth2ClientDelegate.h"

#import "NXOAuth2Connection.h"
#import "NXOAuth2Account.h"
#import "NXOAuth2Account+Private.h"

#import "NXApplication.h"
#import "NXOAuth2AccountStore.h"


#pragma mark Notifications

NSString * const NXOAuth2AccountStoreDidFailToRequestAccessNotification = @"NXOAuth2AccountStoreDidFailToRequestAccessNotification";
NSString * const NXOAuth2AccountStoreAccountsDidChangeNotification = @"NXOAuth2AccountStoreAccountsDidChangeNotification";

NSString * const NXOAuth2AccountStoreNewAccountUserInfoKey = @"NXOAuth2AccountStoreNewAccountUserInfoKey";

#pragma mark Configuration

NSString * const kNXOAuth2AccountStoreConfigurationClientID = @"kNXOAuth2AccountStoreConfigurationClientID";
NSString * const kNXOAuth2AccountStoreConfigurationSecret = @"kNXOAuth2AccountStoreConfigurationSecret";
NSString * const kNXOAuth2AccountStoreConfigurationAuthorizeURL = @"kNXOAuth2AccountStoreConfigurationAuthorizeURL";
NSString * const kNXOAuth2AccountStoreConfigurationTokenURL = @"kNXOAuth2AccountStoreConfigurationTokenURL";
NSString * const kNXOAuth2AccountStoreConfigurationRedirectURL = @"kNXOAuth2AccountStoreConfigurationRedirectURL";
NSString * const kNXOAuth2AccountStoreConfigurationScope = @"kNXOAuth2AccountStoreConfigurationScope";
NSString * const kNXOAuth2AccountStoreConfigurationTokenType = @"kNXOAuth2AccountStoreConfigurationTokenType";
NSString * const kNXOAuth2AccountStoreConfigurationTokenRequestHTTPMethod = @"kNXOAuth2AccountStoreConfigurationTokenRequestHTTPMethod";
NSString * const kNXOAuth2AccountStoreConfigurationKeyChainGroup = @"kNXOAuth2AccountStoreConfigurationKeyChainGroup";
NSString * const kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters = @"kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters";
NSString * const kNXOAuth2AccountStoreConfigurationCustomHeaderFields = @"kNXOAuth2AccountStoreConfigurationCustomHeaderFields";

#pragma mark Account Type

NSString * const kNXOAuth2AccountStoreAccountType = @"kNXOAuth2AccountStoreAccountType";

#pragma mark -


@interface NXOAuth2AccountStore () <NXOAuth2ClientDelegate, NXOAuth2TrustDelegate>

-(instancetype)initWithApplication:(id<NXApplication>)uiApplication;

@property (nonatomic, strong, readwrite) NSMutableDictionary *pendingOAuthClients;
@property (nonatomic, strong, readwrite) NSMutableDictionary *accountsDict;

@property (nonatomic, strong, readwrite) NSMutableDictionary *configurations;
@property (nonatomic, strong, readwrite) NSMutableDictionary *trustModeHandler;
@property (nonatomic, strong, readwrite) NSMutableDictionary *trustedCertificatesHandler;

#pragma mark OAuthClient to AccountType Relation
- (NXOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
- (NSString *)accountTypeOfPendingOAuthClient:(NXOAuth2Client *)oauthClient;


#pragma mark Notification Handler
- (void)accountDidChangeUserData:(NSNotification *)aNotification;
- (void)accountDidChangeAccessToken:(NSNotification *)aNotification;
- (void)accountDidLoseAccessToken:(NSNotification *)aNotification;


#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
+ (NSDictionary *)accountsFromDefaultKeychain;
+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
+ (void)removeFromDefaultKeychain;

@end


@implementation NXOAuth2AccountStore
{
    id<NXApplication> _uiApplication;
}

#pragma mark Lifecycle

+ (instancetype)sharedStoreForApplication:(id<NXApplication>)uiApplication
{
    static NXOAuth2AccountStore *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[NXOAuth2AccountStore alloc] initWithApplication: uiApplication];
    });
    return shared;
}


-(instancetype)initWithApplication:(id)uiApplication
{
    if (nil == uiApplication)
    {
        return nil;
    }

    self = [super init];
    if (nil == self)
    {
        return nil;
    }
    
    self->_uiApplication = uiApplication;
    
    self.pendingOAuthClients = [NSMutableDictionary dictionary];
    self.accountsDict = [NSMutableDictionary dictionaryWithDictionary:[NXOAuth2AccountStore accountsFromDefaultKeychain]];
    self.configurations = [NSMutableDictionary dictionary];
    self.trustModeHandler = [NSMutableDictionary dictionary];
    self.trustedCertificatesHandler = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountDidChangeUserData:)
                                                 name:NXOAuth2AccountDidChangeUserDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountDidChangeAccessToken:)
                                                 name:NXOAuth2AccountDidChangeAccessTokenNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountDidLoseAccessToken:)
                                                 name:NXOAuth2AccountDidLoseAccessTokenNotification
                                               object:nil];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSArray* pendingClients = [self.pendingOAuthClients allValues];
    [self.pendingOAuthClients removeAllObjects];
    for (NXOAuth2Client* singleClient in pendingClients)
    {
        singleClient.delegate = nil;
    }
}


#pragma mark Accessors

@synthesize pendingOAuthClients;
@synthesize accountsDict;

@synthesize configurations;
@synthesize trustModeHandler;
@synthesize trustedCertificatesHandler;

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

- (void)requestAccessToAccountWithType:(NSString *)accountType
   withPreparedAuthorizationURLHandler:(NXOAuth2PreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
{
    NSAssert(aPreparedAuthorizationURLHandler, @"Prepared Authorization Handler must not be nil.");

    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];

    NSDictionary *configuration;
    @synchronized (self.configurations) {
        configuration = [self.configurations objectForKey:accountType];
    }

    NSURL *redirectURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationRedirectURL];
    NSURL *preparedURL = [client authorizationURLWithRedirectURL:redirectURL];

    aPreparedAuthorizationURLHandler(preparedURL);
}

- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
{
    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithUsername:username password:password];
}

- (void)requestAccessToAccountWithType:(NSString *)accountType assertionType:(NSURL *)assertionType assertion:(NSString *)assertion;
{
    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithAssertionType:assertionType assertion:assertion];
}

- (void)requestClientCredentialsAccessWithType:(NSString *)accountType;
{
    NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithClientCredentials];
}

- (void)removeAccount:(NXOAuth2Account *)account;
{
    if (account) {
        @synchronized (self.accountsDict) {
            [self.accountsDict removeObjectForKey:account.identifier];
            [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreAccountsDidChangeNotification object:self];
    }
}

#pragma mark Configuration

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
     forAccountType:(NSString *)anAccountType;
{
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kNXOAuth2AccountStoreConfigurationClientID,
                            aSecret, kNXOAuth2AccountStoreConfigurationSecret,
                            anAuthorizationURL, kNXOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kNXOAuth2AccountStoreConfigurationTokenURL,
                            aRedirectURL, kNXOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
     forAccountType:(NSString *)anAccountType;
{
    NSAssert(aKeyChainGroup, @"keyChainGroup must be non-nil");
    
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kNXOAuth2AccountStoreConfigurationClientID,
                            aSecret, kNXOAuth2AccountStoreConfigurationSecret,
                            theScope, kNXOAuth2AccountStoreConfigurationScope,
                            anAuthorizationURL, kNXOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kNXOAuth2AccountStoreConfigurationTokenURL,
                            aKeyChainGroup, kNXOAuth2AccountStoreConfigurationKeyChainGroup,
                            aRedirectURL, kNXOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
          tokenType:(NSString *)aTokenType
     forAccountType:(NSString *)anAccountType;
{
    NSAssert(aKeyChainGroup, @"keyChainGroup must be non-nil");
    NSAssert(aTokenType, @"tokenType must be non-nil");
    
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kNXOAuth2AccountStoreConfigurationClientID,
                            aSecret, kNXOAuth2AccountStoreConfigurationSecret,
                            theScope, kNXOAuth2AccountStoreConfigurationScope,
                            anAuthorizationURL, kNXOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kNXOAuth2AccountStoreConfigurationTokenURL,
                            aTokenType, kNXOAuth2AccountStoreConfigurationTokenType,
                            aKeyChainGroup, kNXOAuth2AccountStoreConfigurationKeyChainGroup,
                            aRedirectURL, kNXOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setConfiguration:(NSDictionary *)configuration
          forAccountType:(NSString *)accountType;
{
    NSAssert1([configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID], @"Missing OAuth2 client ID for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret], @"Missing OAuth2 client secret for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL], @"Missing OAuth2 authorize URL for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL], @"Missing OAuth2 token URL for account type '%@'.", accountType);

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


#pragma mark Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType
                                    block:(NXOAuth2TrustModeHandler)handler;
{
    @synchronized (self.trustModeHandler) {
        [self.trustModeHandler setObject:[handler copy] forKey:accountType];
    }
}

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType
                                              block:(NXOAuth2TrustedCertificatesHandler)handler;
{
    @synchronized (self.trustedCertificatesHandler) {
        [self.trustedCertificatesHandler setObject:[handler copy] forKey:accountType];
    }
}

- (NXOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;
{
    return [self.trustModeHandler objectForKey:accountType];
}

- (NXOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;
{
    NXOAuth2TrustedCertificatesHandler handler = [self.trustedCertificatesHandler objectForKey:accountType];
    NSAssert(handler, @"You need to provied a NXOAuth2TrustedCertificatesHandler for account type '%@' because you are using 'NXOAuth2TrustModeSpecificCertificate' as trust mode for that account type.", accountType);
    return handler;
}


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)aURL;
{
    __block NSURL *fixedRedirectURL = nil;
    NSSet *accountTypes;

    @synchronized (self.configurations) {
        accountTypes = [self.configurations keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
            NSDictionary *configuration = obj;
            NSURL *redirectURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationRedirectURL];
            if ( [[[aURL absoluteString] lowercaseString] hasPrefix:[[redirectURL absoluteString] lowercaseString]]) {

                // WORKAROUND: The URL which is passed to this method may be lower case also the scheme is registered in camel case. Therefor replace the prefix with the stored redirectURL.
                if (fixedRedirectURL == nil) {
                    if ([aURL.scheme isEqualToString:redirectURL.scheme]) {
                        fixedRedirectURL = aURL;
                    } else {
                        NSRange prefixRange;
                        prefixRange.location = 0;
                        prefixRange.length = [redirectURL.absoluteString length];
                        fixedRedirectURL = [NSURL URLWithString:[aURL.absoluteString stringByReplacingCharactersInRange:prefixRange
                                                                                                             withString:redirectURL.absoluteString]];
                    }
                }

                return YES;
            } else {
                return NO;
            }
        }];
    }

    for (NSString *accountType in accountTypes) {
        NXOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
        if ([client openRedirectURL:fixedRedirectURL]) {
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
            NSSet *scope = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationScope];
            NSURL *authorizeURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL];
            NSString *tokenType = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenType];
            NSString *tokenRequestHTTPMethod = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenRequestHTTPMethod];
            NSString *keychainGroup = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationKeyChainGroup];
            NSDictionary *additionalAuthenticationParameters = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters];
            NSDictionary *customHeaderFields = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationCustomHeaderFields];

            client = [[NXOAuth2Client alloc] initWithClientID:clientID
                                                 clientSecret:clientSecret
                                                 authorizeURL:authorizeURL
                                                     tokenURL:tokenURL
                                                  accessToken:nil
                                                    tokenType:tokenType
                                                keyChainGroup:keychainGroup
                                                   persistent:YES
                                                     delegate:self];

            client.persistent = NO;

            if (tokenRequestHTTPMethod != nil) {
                client.tokenRequestHTTPMethod = tokenRequestHTTPMethod;
            }
            if (additionalAuthenticationParameters != nil) {
                NSAssert([additionalAuthenticationParameters isKindOfClass:[NSDictionary class]], @"additionalAuthenticationParameters have to be a NSDictionary");
                client.additionalAuthenticationParameters = additionalAuthenticationParameters;
            }
            if (customHeaderFields) {
                client.customHeaderFields = customHeaderFields;
            }

            if (scope != nil) {
                client.desiredScope = scope;
            }

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

    
    NSParameterAssert(nil != self->_uiApplication);
    [self->_uiApplication openURL: preparedURL];
}

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client
{
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }

    NXOAuth2Account *account = [[NXOAuth2Account alloc] initAccountWithOAuthClient:client
                                                                       accountType:accountType
                                                                       application:self->_uiApplication];

    [self addAccount:account];
}

- (void)oauthClientDidRefreshAccessToken:(NXOAuth2Client *)client
{
    NXOAuth2Account* foundAccount = nil;

    @synchronized (self.accountsDict)
    {
        for (NXOAuth2Account* account in self.accounts)
        {
            if (account.oauthClient == client)
            {
                foundAccount = account;
                break;
            }
        }
    }
    
    foundAccount.accessToken = client.accessToken;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject: foundAccount
                                                         forKey: NXOAuth2AccountStoreNewAccountUserInfoKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)addAccount:(NXOAuth2Account *)account;
{
    @synchronized (self.accountsDict) {
        [self.accountsDict setValue:account forKey:account.identifier];
        [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:account
                                                         forKey:NXOAuth2AccountStoreNewAccountUserInfoKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    // This delegate method should never be called because the account store
    // does not act as an delegate for established connections.

    // If there is one case that was overlooked, we will remove the oauth
    // client from the list of pending oauth clients as a precaution.
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        if (accountType) {
            [self.pendingOAuthClients removeObjectForKey:accountType];
        }
    }
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        
        if (nil != accountType)
        {
            [self.pendingOAuthClients removeObjectForKey:accountType];
        }
    }

    NSDictionary *userInfo = nil;
    if (nil != accountType)
    {
        userInfo = @{kNXOAuth2AccountStoreAccountType: accountType, NXOAuth2AccountStoreErrorKey : error};
    }
    else
    {
        userInfo = @{NXOAuth2AccountStoreErrorKey : error};
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName: NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                        object: self
                                                      userInfo: userInfo];
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

#pragma mark Notification Handler

- (void)accountDidChangeUserData:(NSNotification *)aNotification;
{
    @synchronized (self.accountsDict) {
        // The user data of an account has been changed.
        // Save all accounts in the default keychain.
        [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }
}

- (void)accountDidChangeAccessToken:(NSNotification *)aNotification;
{
    @synchronized (self.accountsDict) {
        // An access token of an account has been changed.
        // Save all accounts in the default keychain.
        [NXOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }
}

- (void)accountDidLoseAccessToken:(NSNotification *)aNotification;
{
    NSLog(@"Removing account with id '%@' from account store because it lost its access token.", [aNotification.object identifier]);
    [self removeAccount:aNotification.object];
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
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFTypeRef cfResult = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &cfResult);
    result = (__bridge_transfer NSDictionary *)cfResult;

    if (status != noErr) {
        NSAssert1(status == errSecItemNotFound, @"Unexpected error while fetching accounts from keychain: %zd", status);
        return nil;
    }

    return [NSKeyedUnarchiver unarchiveObjectWithData:[result objectForKey:(__bridge NSString *)kSecAttrGeneric]];
}

+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
{
    [self removeFromDefaultKeychain];

    NSString *serviceName = [self keychainServiceName];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accounts];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           @"OAuth 2 Account Store", kSecAttrLabel,
                           data, kSecAttrGeneric,
                           nil];
    OSStatus __attribute__((unused)) err = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    NSAssert1(err == noErr, @"Error while adding token to keychain: %zd", err);
}

+ (void)removeFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           nil];
    OSStatus __attribute__((unused)) err = SecItemDelete((__bridge CFDictionaryRef)query);
    NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting token from keychain: %zd", err);

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

