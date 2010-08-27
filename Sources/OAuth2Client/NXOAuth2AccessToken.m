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

- (id)initWithSomething;
{
	if (self = [super init]) {
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

@dynamic accessToken;
@dynamic refreshToken;
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
	return [NSString stringWithFormat:@"<NXOAuth2Token token:%@ expiresAt:%@>", self.accessToken, self.expiresAt];
}


#pragma mark Keychain

- (id)initWithDefaultKeychainUsingAppName:(NSString *)name serviceProviderName:(NSString *)provider;
{
	NSDictionary *result = nil;
	NSString *serviceName = [NSString stringWithFormat:@"%@::OAuth2::%@", name, provider];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   kCFBooleanTrue, kSecReturnAttributes,
						   nil];
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
	
	if (status != noErr) {
		if (status != errSecItemNotFound) {
			NSLog(@"Error while initializing OAtoken: %d", status);
		}
		[result release];
		return nil;
	}
	
	if (self = [self init]) {
		self.key = [result objectForKey:(NSString *)kSecAttrAccount];
		self.secret = [result objectForKey:(NSString *)kSecAttrGeneric];
	}
	[result release];
	return self;
}

- (int)storeInDefaultKeychainWithAppName:(NSString *)name serviceProviderName:(NSString *)provider;
{
	NSString *serviceName = [NSString stringWithFormat:@"%@::OAuth2::%@", name, provider];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   @"SoundCloud API OAuth Token", kSecAttrLabel,
						   self.key, kSecAttrAccount,
						   self.secret, kSecAttrGeneric,
						   nil];
	[self removeFromDefaultKeychainWithAppName:name serviceProviderName:provider];
	return SecItemAdd((CFDictionaryRef)query, NULL);
}

- (int)removeFromDefaultKeychainWithAppName:(NSString *)name serviceProviderName:(NSString *)provider;
{
	NSString *serviceName = [NSString stringWithFormat:@"%@::OAuth2::%@", name, provider];	
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (NSString *)kSecClassGenericPassword, kSecClass,
						   serviceName, kSecAttrService,
						   nil];
	return SecItemDelete((CFDictionaryRef)query);
}

@end
