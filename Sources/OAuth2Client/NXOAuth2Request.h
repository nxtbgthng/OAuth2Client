//
//  NXOAuth2Request.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NXOAuth2RequestHandler)(NSData *responseData, NSError *error);

@class NXOAuth2Account;
@class NXOAuth2Connection;

@interface NXOAuth2Request : NSObject {
@private    
    NSDictionary *parameters;
    NSURL *URL;
    NSString * requestMethod;
    NXOAuth2Account *account;
    NXOAuth2Connection *connection;
    NXOAuth2RequestHandler handler;
    BOOL should_release;
}

#pragma mark Lifecycle

+ (id)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(NSString *)requestMethod;
- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(NSString *)requestMethod;


#pragma mark Accessors

@property(nonatomic, readwrite, retain) NXOAuth2Account *account;
@property(nonatomic, readonly) NSDictionary *parameters;
@property(nonatomic, readonly) NSString *requestMethod;
@property(nonatomic, readonly) NSURL *URL;


#pragma mark Perform Request

- (void)performRequestWithHandler:(NXOAuth2RequestHandler)handler;

@end
