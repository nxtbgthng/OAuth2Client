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
@property (nonatomic, retain) NXOAuth2RequestHandler handler;
- (void)setShouldRelease:(BOOL)r;
@end


@implementation NXOAuth2Request

#pragma mark Lifecycle

+ (id)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(NSString *)requestMethod;
{
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithURL:url parameters:parameters requestMethod:requestMethod];
    [request retain];
    [request setShouldRelease:YES];
    return request;
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


- (void)setShouldRelease:(BOOL)r;
{
    should_release = YES;
}

#pragma mark Perform Request

- (void)performRequestWithHandler:(NXOAuth2RequestHandler)aHandler;
{
    self.handler = [[aHandler copy] autorelease];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
}


#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.handler(data, nil);
    self.handler = nil;
    self.connection = nil;
    
    if (should_release) {
        [self release];
        should_release = NO;
    }
}

- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.handler(nil, error);
    self.handler = nil;
    self.connection = nil;
    
    if (should_release) {
        [self release];
        should_release = NO;
    }
}

@end
