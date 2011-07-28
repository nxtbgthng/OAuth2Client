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
@property (nonatomic, retain) NXOAuth2Connection *connection;
@property (nonatomic, retain) NXOAuth2Request *me;
#pragma mark Apply Parameters
- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
@end


@implementation NXOAuth2Request

#pragma mark Class Methods

+ (void)performMethod:(NSString *)aMethod
           onResource:(NSURL *)aResource
      usingParameters:(NSDictionary *)someParameters
          withAccount:(NXOAuth2Account *)anAccount
  sendProgressHandler:(NXOAuth2RequestSendProgressHandler)aProgressHandler
      responseHandler:(NXOAuth2RequestResponseHandler)aResponseHandler;
{
    NXOAuth2Request *r = [NXOAuth2Request requestOnResource:aResource
                                                 withMethod:aMethod
                                            usingParameters:someParameters];
    r.account = anAccount;
    r.responseHandler = aResponseHandler;
    r.sendProgressHandler = aProgressHandler;
    [r performRequest];
}

+ (NXOAuth2Request *)requestOnResource:(NSURL *)aResource
                            withMethod:(NSString *)aMethod
                       usingParameters:(NSDictionary *)someParameters;
{
    return [[[NXOAuth2Request alloc] initWithResource:aResource
                                               method:aMethod
                                           parameters:someParameters] autorelease];
}

+ (NXOAuth2Request *)request;
{
    return [[self new] autorelease];
}

#pragma mark Lifecycle

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
    [sendProgressHandler release];
    [super dealloc];
}


#pragma mark Accessors

@synthesize parameters;
@synthesize resource;
@synthesize requestMethod;
@synthesize account;
@synthesize connection;
@synthesize responseHandler;
@synthesize sendProgressHandler;
@synthesize me;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    
    [request setHTTPMethod:self.requestMethod];
    
    [self applyParameters:self.parameters onRequest:request];
    
    if (self.account.oauthClient.userAgent && ![request valueForHTTPHeaderField:@"User-Agent"]) {
        [request setValue:self.account.oauthClient.userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    if (self.account) {
        NSString *oauthAuthorizationHeader = [NSString stringWithFormat:@"OAuth %@", self.account.accessToken.accessToken];
        [request setValue:oauthAuthorizationHeader forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}


#pragma mark Perform Request

- (void)performRequest;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
    
    // Keep request object alive during the request is performing.
    self.me = self;
}

#pragma mark Cancel

- (void)cancel;
{
    [self.connection cancel];
    self.responseHandler = nil;
    self.sendProgressHandler = nil;
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    if (self.responseHandler) {
        self.responseHandler(self.connection.response, data, nil);
    }
    self.responseHandler = nil;
    self.sendProgressHandler = nil;
    self.connection = nil;

    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    if (self.responseHandler) {
        self.responseHandler(self.connection.response, nil, error);
    }
    self.responseHandler = nil;
    self.sendProgressHandler = nil;
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    [[self.me retain] autorelease];
    self.me = nil;
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;
{
    if (self.sendProgressHandler) {
        self.sendProgressHandler(bytesSend, bytesTotal);
    }
}

#pragma mark Apply Parameters

- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
{
	if (!someParameters) return;
	
	NSString *httpMethod = [aRequest HTTPMethod];
	if ([httpMethod caseInsensitiveCompare:@"POST"] != NSOrderedSame
		&& [httpMethod caseInsensitiveCompare:@"PUT"] != NSOrderedSame) {
		aRequest.URL = [aRequest.URL nxoauth2_URLByAddingParameters:someParameters];
	} else {
		NSInputStream *postBodyStream = [[NXOAuth2PostBodyStream alloc] initWithParameters:parameters];
		
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", [(NXOAuth2PostBodyStream *)postBodyStream boundary]];
		NSString *contentLength = [NSString stringWithFormat:@"%d", [(NXOAuth2PostBodyStream *)postBodyStream length]];
		[aRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
		[aRequest setValue:contentLength forHTTPHeaderField:@"Content-Length"];
		
		[aRequest setHTTPBodyStream:postBodyStream];
		[postBodyStream release];
	}
}

@end
