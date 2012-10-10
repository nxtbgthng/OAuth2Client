//
//  NXOAuth2AccessToken.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>


@interface NXOAuth2AccessToken : NSObject <NSCoding> {
@private
    NSString *accessToken;
    NSString *refreshToken;
    NSString *tokenType;
    NSDate *expiresAt;
    NSSet *scope;
    NSString *responseBody;
}
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *refreshToken;
@property (nonatomic, readonly) NSString *tokenType;
@property (nonatomic, readonly) NSDate *expiresAt;
@property (nonatomic, readonly) BOOL doesExpire;
@property (nonatomic, readonly) BOOL hasExpired;
@property (nonatomic, readonly) NSSet *scope;
@property (nonatomic, readonly) NSString *responseBody;

+ (id)tokenWithResponseBody:(NSString *)responseBody;
+ (id)tokenWithResponseBody:(NSString *)responseBody tokenType:(NSString *)tokenType;

- (id)initWithAccessToken:(NSString *)accessToken;
- (id)initWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken expiresAt:(NSDate *)expiryDate;
- (id)initWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken expiresAt:(NSDate *)expiryDate scope:(NSSet *)scope;
- (id)initWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken expiresAt:(NSDate *)expiryDate scope:(NSSet *)scope responseBody:(NSString *)responseBody;
- (id)initWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken expiresAt:(NSDate *)expiryDate scope:(NSSet *)scope responseBody:(NSString *)responseBody tokenType:(NSString*)tokenType; // designated

- (void)restoreWithOldToken:(NXOAuth2AccessToken *)oldToken;

#pragma mark Keychain Support

//TODO: Support alternate KeyChain Locations

+ (id)tokenFromDefaultKeychainWithServiceProviderName:(NSString *)provider;
- (void)storeInDefaultKeychainWithServiceProviderName:(NSString *)provider;
- (void)removeFromDefaultKeychainWithServiceProviderName:(NSString *)provider;

@end
