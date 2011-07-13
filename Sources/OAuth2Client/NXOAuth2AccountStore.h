//
//  NXOAuth2AccountStore.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class NXOAuth2Account;

@interface NXOAuth2AccountStore : NSObject <NXOAuth2ClientDelegate>


+ (id)sharedStore;

#pragma mark Accessors

@property(nonatomic, readonly) NSArray *accounts;
- (NSArray *)accountsWithAccountType:(NSString *)accountType;
- (NXOAuth2Account *)accountWithIdentifier:(NSString *)identifier;

#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
- (void)removeAccount:(NXOAuth2Account *)account;

#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)URL forAccountWithType:(NSString *)accountType;

@end
