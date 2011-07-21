//
//  NXOAuth2Request.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Connection.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2Account.h"

#import "NXOAuth2Request.h"

@interface NXOAuth2Request () <NXOAuth2ConnectionDelegate>
@property (nonatomic, retain) NXOAuth2Connection *connection;
@property (nonatomic, retain) NXOAuth2RequestResponseHandler responseHandler;
@property (nonatomic, retain) NXOAuth2RequestProgressHandler progressHandler;
@property (nonatomic, retain) NXOAuth2Request *me;
@end


@implementation NXOAuth2Request


+ (void)performMethod:(NSString *)aMethod
           onResource:(NSURL *)aResource
      usingParameters:(NSDictionary *)someParameters
          withAccount:(NXOAuth2Account *)anAccount
  sendProgressHandler:(NXOAuth2RequestProgressHandler)aProgressHandler
      responseHandler:(NXOAuth2RequestResponseHandler)aResponseHandler;
{
    NXOAuth2Request *r = [NXOAuth2Request requestOnResource:aResource
                                                 withMethod:aMethod
                                            usingParameters:someParameters];
    r.account = anAccount;
    [r performRequestWithResponseHandler:aResponseHandler
                     sendProgressHandler:aProgressHandler];
}


#pragma mark Lifecycle

+ (id)requestOnResource:(NSURL *)aResource withMethod:(NSString *)aMethod usingParameters:(NSDictionary *)someParameters;
{
    return [[[NXOAuth2Request alloc] initWithResource:aResource
                                               method:aMethod
                                           parameters:someParameters] autorelease];
}

- (id)initWithResource:(NSURL *)aResource method:(NSString *)aMethod parameters:(NSDictionary *)someParameters;
{
    self = [super init];
    if (self) {
        resource = [aResource retain];
        parameters = [someParameters retain];
        requestMethod = [aMethod retain];
    }
    return self;
}

- (void)dealloc;
{
    [parameters release];
    [resource release];
    [requestMethod release];
    [account release];
    [connection release];
    [responseHandler release];
    [progressHandler release];
    [super dealloc];
}


#pragma mark Accessors

@synthesize parameters;
@synthesize resource;
@synthesize requestMethod;
@synthesize account;
@synthesize connection;
@synthesize responseHandler;
@synthesize progressHandler;
@synthesize me;


#pragma mark Perform Request

- (void)performRequestWithResponseHandler:(NXOAuth2RequestResponseHandler)aHandler;
{
    NSAssert(self.me == nil, @"This object can perform only one request at the same time.");
    
    self.responseHandler = [[aHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    // Break this cycle after the connection did finish.
    self.me = self;
}

- (void)performRequestWithResponseHandler:(NXOAuth2RequestResponseHandler)aResponseHandler sendProgressHandler:(NXOAuth2RequestProgressHandler)aProgressHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    self.responseHandler = [[aResponseHandler copy] autorelease];
    self.progressHandler = [[aProgressHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    self.me = self;
}

- (void)performRequestWithResponseHandler:(NXOAuth2RequestResponseHandler)aResponseHandler progressHandler:(NXOAuth2RequestProgressHandler)aProgressHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    self.responseHandler = [[aResponseHandler copy] autorelease];
    self.progressHandler = [[aProgressHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    self.me = self;
}

- (void)cancel;
{
    [self.connection cancel];
    self.responseHandler = nil;
    self.progressHandler = nil;
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.responseHandler(data, nil);
    self.responseHandler = nil;
    self.progressHandler = nil;
    self.connection = nil;

    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.responseHandler(nil, error);
    self.responseHandler = nil;
    self.progressHandler = nil;
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;
{
    self.progressHandler(bytesSend, bytesTotal);
}

@end
