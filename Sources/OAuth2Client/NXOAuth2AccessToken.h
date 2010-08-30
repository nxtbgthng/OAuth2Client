//
//  NXOAuth2AccessToken.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NXOAuth2AccessToken : NSObject {
@private
	NSString *accessToken;
	NSString *refreshToken;
	NSDate *expiresAt;
}
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *refreshToken;
@property (nonatomic, readonly) NSDate *expiresAt;
@property (nonatomic, readonly) BOOL doesExpire;
@property (nonatomic, readonly) BOOL hasExpired;

+ (id)tokenWithResponseBody:(NSString *)responseBody;

- (id)initWithAccessToken:(NSString *)accessToken;
- (id)initWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken expiresAt:(NSDate *)expiryDate;	// designated

@end
