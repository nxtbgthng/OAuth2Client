//
//  NXOAuth2AccountStoreDelegate.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NXOAuth2AccountStoreDelegate <NSObject>

- (NSString *)clientIDForAccountsWithType:(NSString *)accountType;
- (NSString *)secretForAccountsWithType:(NSString *)accountType;
- (NSURL *)authorizeURLForAccountsWithType:(NSString *)accountType;
- (NSURL *)tokenURLForAccountsWithType:(NSString *)accountType;
- (NSURL *)redirectURLForAccountsWithType:(NSString *)accountType;

@end
