//
//  NXOAuth2AccountStore.h
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

#import <Foundation/Foundation.h>

#import "NXOAuth2TrustDelegate.h"

@class NXOAuth2Account;
@class NXOAuth2Connection;

#pragma mark Notifications

extern NSString * const NXOAuth2AccountStoreDidFailToRequestAccessNotification;
extern NSString * const NXOAuth2AccountStoreAccountsDidChangeNotification;

extern NSString * const NXOAuth2AccountStoreNewAccountUserInfoKey;

#pragma mark Configuration

extern NSString * const kNXOAuth2AccountStoreConfigurationClientID;
extern NSString * const kNXOAuth2AccountStoreConfigurationSecret;
extern NSString * const kNXOAuth2AccountStoreConfigurationAuthorizeURL;
extern NSString * const kNXOAuth2AccountStoreConfigurationTokenURL;
extern NSString * const kNXOAuth2AccountStoreConfigurationRedirectURL;


#pragma mark Account Type

extern NSString * const kNXOAuth2AccountStoreAccountType;


#pragma mark Handler

typedef NXOAuth2TrustMode(^NXOAuth2TrustModeHandler)(NXOAuth2Connection *connection, NSString *hostname);
typedef NSArray *(^NXOAuth2TrustedCertificatesHandler)(NSString *hostname);
typedef void(^NXOAuth2PreparedAuthorizationURLHandler)(NSURL *preparedURL);


#pragma mark -

@interface NXOAuth2AccountStore : NSObject {
@private
    NSMutableDictionary *pendingOAuthClients;
    NSMutableDictionary *accountsDict;
    NSMutableDictionary *configurations;
    NSMutableDictionary *trustModeHandler;
    NSMutableDictionary *trustedCertificatesHandler;
}

+ (id)sharedStore;

#pragma mark Accessors

@property(nonatomic, strong, readonly) NSArray *accounts;
- (NSArray *)accountsWithAccountType:(NSString *)accountType;
- (NXOAuth2Account *)accountWithIdentifier:(NSString *)identifier;


#pragma mark Configuration

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
     forAccountType:(NSString *)anAccountType;

- (void)setConfiguration:(NSDictionary *)configuration forAccountType:(NSString *)accountType;

- (NSDictionary *)configurationForAccountType:(NSString *)accountType;


#pragma Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType block:(NXOAuth2TrustModeHandler)handler;
- (NXOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType block:(NXOAuth2TrustedCertificatesHandler)handler;
- (NXOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
- (void)requestAccessToAccountWithType:(NSString *)accountType withPreparedAuthorizationURLHandler:(NXOAuth2PreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
- (void)requestAccessToAccountWithType:(NSString *)accountType assertionType:(NSURL *)assertionType assertion:(NSString *)assertion;
- (void)removeAccount:(NXOAuth2Account *)account;


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)URL;

@end
