//
//  NXOAuth2Request.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Connection.h"
#import "NXOAuth2Account.h"

#import "NXOAuth2Request.h"

@interface NXOAuth2Request ()
@property (nonatomic, retain) NXOAuth2Connection *connection;
@property (nonatomic, readonly) NXOAuth2RequestHandler handler;
@end


@implementation NXOAuth2Request

#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)aURL parameters:(NSDictionary *)someParameters requestMethod:(NXOAuth2RequestMethod)aRequestMethod;
{
    self = [super init];
    if (self) {
        URL = [aURL retain];
        parameters = [someParameters retain];
        requestMethod = aRequestMethod;
    }
    return self;
}

#pragma mark Accessors

@synthesize account;
@synthesize parameters;
@synthesize requestMethod;
@synthesize URL;

@synthesize connection;
@synthesize handler;

#pragma mark Perform Request

- (void)performRequestWithHandler:(NXOAuth2RequestHandler)aHandler;
{
    [handler release];
    handler = [aHandler copy];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    
    switch (self.requestMethod) {
        case NXOAuth2RequestMethodDELETE:
            [request setHTTPMethod:@"DELETE"];
            break;
            
        case NXOAuth2RequestMethodPOST:
            [request setHTTPMethod:@"POST"];
            break;
            
        default:
            [request setHTTPMethod:@"GET"];
            break;
    }

    self.connection = [[[NXOAuth2Connection alloc] initWithRequest:request
                                                 requestParameters:self.parameters
                                                       oauthClient:self.account.oauthClient
                                                          delegate:self] autorelease];
}

#pragma mark NXOAuth2ConnectionDelegate


- (void)oauthConnection:(NXOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.handler(data, nil);
    [handler release];
}


- (void)oauthConnection:(NXOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.handler(nil, error);
    [handler release];
}

@end
