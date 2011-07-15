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
@property (nonatomic, retain) NXOAuth2RequestResponseHandler handler;
@property (nonatomic, retain) NXOAuth2RequestProgressHandler progresHandler;
@property (nonatomic, retain) NXOAuth2Request *me;
@end


@implementation NXOAuth2Request

#pragma mark Lifecycle

+ (id)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(NSString *)requestMethod;
{
    return [[[NXOAuth2Request alloc] initWithURL:url parameters:parameters requestMethod:requestMethod] autorelease];
}

- (id)initWithURL:(NSURL *)aURL parameters:(NSDictionary *)someParameters requestMethod:(NSString *)aRequestMethod;
{
    self = [super init];
    if (self) {
        URL = [aURL retain];
        parameters = [someParameters retain];
        requestMethod = [aRequestMethod retain];
    }
    return self;
}

- (void)dealloc;
{
    [parameters release];
    [URL release];
    [requestMethod release];
    [account release];
    [connection release];
    [handler release];
    [super dealloc];
}


#pragma mark Accessors

@synthesize parameters;
@synthesize URL;
@synthesize requestMethod;
@synthesize account;
@synthesize connection;
@synthesize handler;
@synthesize progresHandler;
@synthesize me;


#pragma mark Perform Request

- (void)performRequestWithResponseHandler:(NXOAuth2RequestResponseHandler)aHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    self.handler = [[aHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    self.me = self;
}

- (void)performRequestWithResponseHandler:(NXOAuth2RequestResponseHandler)aResponseHandler progressHandler:(NXOAuth2RequestProgressHandler)aProgresHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    self.handler = [[aResponseHandler copy] autorelease];
    self.progresHandler = [[aProgresHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    self.me = self;
}


#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.handler(data, nil);
    self.handler = nil;
    self.progresHandler = nil;
    self.connection = nil;

    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.handler(nil, error);
    self.handler = nil;
    self.progresHandler = nil;
    self.connection = nil;
    
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;
{
    self.progresHandler(((float)bytesSend)/bytesTotal);
}

@end
