//
//  NXOAuth2Request.m
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

#import "NXOAuth2Connection.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2AccessToken.h"
#import "NXOAuth2Account.h"
#import "NXOAuth2Client.h"
#import "NXOAuth2PostBodyStream.h"

#import "NSURL+NXOAuth2.h"

#import "NXOAuth2Request.h"


@interface NXOAuth2Request () <NXOAuth2ConnectionDelegate>
@property (nonatomic,  strong, readwrite) NXOAuth2Connection *connection;
@property (nonatomic,  strong, readwrite) NXOAuth2Request *me;
#pragma mark Apply Parameters
- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
- (void)applyHeaders:(NSDictionary *)someHeaders onRequest:(NSMutableURLRequest *)aRequest;
@end


@implementation NXOAuth2Request

#pragma mark Class Methods

+ (void)performMethod:(NSString *)aMethod
           onResource:(NSURL *)aResource
      usingParameters:(NSDictionary *)someParameters
          withAccount:(NXOAuth2Account *)anAccount
  sendProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler;
{
    [self performMethod:aMethod
             onResource:aResource
        usingParameters:someParameters
           usingHeaders:nil
            withAccount:anAccount
    sendProgressHandler:progressHandler
        responseHandler:responseHandler];
}

+ (void)performMethod:(NSString *)aMethod
           onResource:(NSURL *)aResource
      usingParameters:(NSDictionary *)someParameters
         usingHeaders:(NSDictionary *)someHeaders
          withAccount:(NXOAuth2Account *)anAccount
  sendProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler
{
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:aResource
                                                                  method:aMethod
                                                              parameters:someParameters];
    request.account = anAccount;
    request.headerFields = someHeaders;
    [request performRequestWithSendingProgressHandler:progressHandler responseHandler:responseHandler];
}


#pragma mark Lifecycle

- (instancetype)initWithResource:(NSURL *)aResource method:(NSString *)aMethod parameters:(NSDictionary *)someParameters;
{
    self = [super init];
    if (self) {
        resource = aResource;
        parameters = someParameters;
        requestMethod = aMethod;
    }
    return self;
}


- (instancetype)initWithResource:(NSURL *)aResource method:(NSString *)aMethod contentType:(NSString *) aContentType parameters:(NSDictionary *)someParameters
{
    self = [super init];
    if (self) {
        resource = aResource;
        parameters = someParameters;
        requestMethod = aMethod;
        requestContentType= aContentType;
    }
    return self;
}

#pragma mark Accessors

@synthesize parameters;
@synthesize resource;
@synthesize requestMethod;
@synthesize requestContentType;
@synthesize account;
@synthesize connection;
@synthesize me;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    
    [request setHTTPMethod:self.requestMethod];
    
    [self applyHeaders:self.headerFields onRequest:request];
    [self applyParameters:self.parameters onRequest:request];
    
    if (self.account.oauthClient.userAgent && ![request valueForHTTPHeaderField:@"User-Agent"]) {
        [request setValue:self.account.oauthClient.userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    if (self.account) {
        NSString *oauthAuthorizationHeader = [NSString stringWithFormat:@"%@ %@", self.account.accessToken.tokenType, self.account.accessToken.accessToken];
        [request setValue:oauthAuthorizationHeader forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(NXOAuth2ConnectionSendingProgressHandler)progressHandler
                                 responseHandler:(NXOAuth2ConnectionResponseHandler)responseHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];

    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    if(self.requestContentType)
    {
        [request setValue:self.requestContentType forHTTPHeaderField:@"Content-Type"];
    }
    
    [self applyHeaders:self.headerFields onRequest:request];

    self.connection = [[NXOAuth2Connection alloc] initWithRequest:request
                                                requestParameters:self.parameters
                                                      oauthClient:self.account.oauthClient
                                           sendingProgressHandler:progressHandler
                                                  responseHandler:responseHandler];
    self.connection.delegate = self;
    
    // Keep request object alive during the request is performing.
    self.me = self;
}


#pragma mark Cancel

- (void)cancel;
{
    [self.connection cancel];
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}

#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.connection = nil;
    
    // Release the reference to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}


#pragma mark Apply Parameters

- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
{
    if (!someParameters) return;
    
    NSString *httpMethod = [aRequest HTTPMethod];
    if (![@[@"POST",@"PUT",@"PATCH"] containsObject: [httpMethod uppercaseString]]) {
        aRequest.URL = [aRequest.URL nxoauth2_URLByAddingParameters:someParameters];
    } else {
        if([requestContentType isEqualToString:jsonContentType]){
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
            if(!error)
            {
                [aRequest setHTTPBody:jsonData];
            }
            [aRequest setValue:requestContentType forHTTPHeaderField:@"Content-Type"];
        } else  {
            NSInputStream *postBodyStream = [[NXOAuth2PostBodyStream alloc] initWithParameters:parameters];
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", [(NXOAuth2PostBodyStream *)postBodyStream boundary]];
            [aRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
            NSString *contentLength = [NSString stringWithFormat:@"%llu", [(NXOAuth2PostBodyStream *)postBodyStream length]];
            [aRequest setValue:contentLength forHTTPHeaderField:@"Content-Length"];
            [aRequest setHTTPBodyStream:postBodyStream];
        }
        
    }
}

- (void)applyHeaders:(NSDictionary *)someHeaders onRequest:(NSMutableURLRequest *)aRequest;
{
    for (id key in someHeaders) {
        id value = someHeaders[key];
        NSAssert1([key isKindOfClass:[NSString class]], @"Header name should be a string. name=%@", key);
        NSAssert2([value isKindOfClass:[NSString class]], @"Header value should be a string. name=%@, value=%@", key, value);
        [aRequest setValue:value forHTTPHeaderField:key];
    }
}

@end
