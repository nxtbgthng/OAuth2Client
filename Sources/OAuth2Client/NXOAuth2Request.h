//
//  NXOAuth2Request.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NXOAuth2RequestResponseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);
typedef void(^NXOAuth2RequestSendProgressHandler)(unsigned long long bytesSend, unsigned long long bytesTotal);

@class NXOAuth2Account;
@class NXOAuth2Connection;

@interface NXOAuth2Request : NSObject {
@private    
    NSDictionary *parameters;
    NSURL *resource;
    NSString * requestMethod;
    NXOAuth2Account *account;
    NXOAuth2Connection *connection;
    NXOAuth2RequestResponseHandler responseHandler;
    NXOAuth2RequestSendProgressHandler sendProgressHandler;
    NXOAuth2Request *me;
}

#pragma mark Class Methods

+ (void)performMethod:(NSString *)method
           onResource:(NSURL *)resource
      usingParameters:(NSDictionary *)parameters
          withAccount:(NXOAuth2Account *)account
  sendProgressHandler:(NXOAuth2RequestSendProgressHandler)progressHandler
      responseHandler:(NXOAuth2RequestResponseHandler)responseHandler;

+ (NXOAuth2Request *)requestOnResource:(NSURL *)url
                            withMethod:(NSString *)method
                       usingParameters:(NSDictionary *)parameter;

+ (NXOAuth2Request *)request;

#pragma mark Lifecycle

- (id)initWithResource:(NSURL *)url method:(NSString *)method parameters:(NSDictionary *)parameter;

#pragma mark Accessors

@property (nonatomic, readwrite, retain) NXOAuth2Account *account;

@property (nonatomic, readwrite, retain) NSString *requestMethod;
@property (nonatomic, readwrite, retain) NSURL *resource;
@property (nonatomic, readwrite, retain) NSDictionary *parameters;

@property (nonatomic, copy) NXOAuth2RequestResponseHandler responseHandler;
@property (nonatomic, copy) NXOAuth2RequestSendProgressHandler sendProgressHandler;

#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;

#pragma mark Perform Request

- (void)performRequest;

#pragma mark Cancel

- (void)cancel;

@end
