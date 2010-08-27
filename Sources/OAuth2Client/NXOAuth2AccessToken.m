//
//  NXOAuth2AccessToken.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2AccessToken.h"


@implementation NXOAuth2AccessToken

#pragma mark Lifecycle

- (id)initWithAccessToken:(NSString *)anAccessToken;
{
	return [self initWithAccessToken:anAccessToken refreshToken:nil expiresAt:nil];
}

- (id)initWithAccessToken:(NSString *)anAccessToken refreshToken:(NSString *)aRefreshToken expiresAt:(NSDate *)anExpiryDate;
{
	if (self = [super init]) {
		accessToken = [anAccessToken copy];
		refreshToken = [aRefreshToken copy];
		expiresAt = [anExpiryDate copy];
	}
	return self;
}

- (void)dealloc;
{
	[accessToken release];
	[refreshToken release];
	[expiresAt release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize accessToken;
@synthesize refreshToken;
@synthesize expiresAt;

- (BOOL)doesExpire;
{
	return (expiresAt != nil);
}

- (BOOL)hasExpired;
{
	return ([[NSDate date] earlierDate:expiresAt] == expiresAt);
}


- (NSString *)description;
{
	return [NSString stringWithFormat:@"<NXOAuth2Token token:%@ refreshToken:%@ expiresAt:%@>", self.accessToken, self.refreshToken, self.expiresAt];
}


@end
