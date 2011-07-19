//
//  NXOAuth2AccountStore.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2TrustDelegate.h"

@class NXOAuth2Account;
@class NXOAuth2Connection;


typedef NXOAuth2TrustMode(^NXOAuth2TrustModeHandler)(NXOAuth2Connection *connection, NSString *hostname);
typedef NSArray *(^NXOAuth2TrustedCertificatesHandler)(NSString *hostname);
typedef void(^NXOAuth2PreparedAuthorizationURLHandler)(NSURL *preparedURL);


@interface NXOAuth2AccountStore : NSObject <NXOAuth2TrustDelegate> {
@private
    NSMutableDictionary *pendingOAuthClients;
    NSMutableDictionary *accountsDict;
    NSMutableDictionary *configurations;
    NSMutableDictionary *trustModeHandler;
    NSMutableDictionary *trustedCertificatesHandler;
    NSMutableDictionary *preparedAuthorizationURLHandler;
    id accountDidChangeUserDataObserver;
    id accountDidChangeAccessTokenObserver;
    id accountDidLoseAccessTokenObserver;
    id accountFailToGetAccessTokenObserver;
}

+ (id)sharedStore;

#pragma mark Accessors

@property(nonatomic, readonly) NSArray *accounts;
- (NSArray *)accountsWithAccountType:(NSString *)accountType;
- (NXOAuth2Account *)accountWithIdentifier:(NSString *)identifier;


#pragma mark Configuration

- (void)setConfiguration:(NSDictionary *)configuration forAccountType:(NSString *)accountType;
- (NSDictionary *)configurationForAccountType:(NSString *)accountType;


#pragma mark Prepared Authorization URL Handler

- (void)setPreparedAuthorizationURLHandlerForAccountType:(NSString *)accountType block:(NXOAuth2PreparedAuthorizationURLHandler)handler;
- (NXOAuth2PreparedAuthorizationURLHandler)preparedAuthorizationURLHandlerForAccountType:(NSString *)accountType;


#pragma Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType block:(NXOAuth2TrustModeHandler)handler;
- (NXOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType block:(NXOAuth2TrustedCertificatesHandler)handler;
- (NXOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
- (void)removeAccount:(NXOAuth2Account *)account;


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)URL;

@end
