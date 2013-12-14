//
//  NXOAuth2Request.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2Connection.h"

#define NXOAuth2DefaultTimeOut 30

@class NXOAuth2Account;

@interface NXOAuth2Request : NSObject {
@private
    NSDictionary *parameters;
    NSURL *resource;
    NSString *requestMethod;
    NXOAuth2Account *account;
    NXOAuth2Connection *connection;
    NXOAuth2Request *me;
}


#pragma mark Class Methods

+ (void)performMethod:(NSString *)method
           onResource:(NSURL *)resource
      usingParameters:(NSDictionary *)parameters
          withAccount:(NXOAuth2Account *)account
  sendProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler;

+ (void)performMethod:(NSString *)method
           onResource:(NSURL *)resource
      usingParameters:(NSDictionary *)parameters
          withAccount:(NXOAuth2Account *)account
  sendProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler
      timeoutinterval:(NSTimeInterval ) time;

#pragma mark Lifecycle

- (id)initWithResource:(NSURL *)url
                method:(NSString *)method
            parameters:(NSDictionary *)parameter;

- (id)initWithResource:(NSURL *)url
                method:(NSString *)method
            parameters:(NSDictionary *)parameter
               timeout:(NSTimeInterval ) time;


#pragma mark Accessors

@property (nonatomic, strong, readwrite) NXOAuth2Account *account;

@property (nonatomic, strong, readwrite) NSString *requestMethod;
@property (nonatomic, strong, readwrite) NSURL *resource;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
                                 responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler;


#pragma mark Cancel

- (void)cancel;

@end
