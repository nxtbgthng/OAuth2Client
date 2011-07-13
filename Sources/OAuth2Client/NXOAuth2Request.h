//
//  NXOAuth2Request.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2ConnectionDelegate.h"

enum NXOAuth2RequestMethod {
    NXOAuth2RequestMethodGET,
    NXOAuth2RequestMethodPOST,
    NXOAuth2RequestMethodDELETE
};
typedef enum NXOAuth2RequestMethod NXOAuth2RequestMethod;

typedef void(^NXOAuth2RequestHandler)(NSData *responseData, NSError *error);

@class NXOAuth2Account;

@interface NXOAuth2Request : NSObject <NXOAuth2ConnectionDelegate> {
    NSDictionary *parameters;
    NXOAuth2RequestMethod requestMethod;
    NSURL *URL;
    
    NXOAuth2Account *account;
    NXOAuth2Connection *connection;
    
    NXOAuth2RequestHandler handler;
}


#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(NXOAuth2RequestMethod)requestMethod;


#pragma mark Accessors

@property(nonatomic, readwrite, retain) NXOAuth2Account *account;
@property(nonatomic, readonly) NSDictionary *parameters;
@property(nonatomic, readonly) NXOAuth2RequestMethod requestMethod;
@property(nonatomic, readonly) NSURL *URL;


#pragma mark Perform Request

- (void)performRequestWithHandler:(NXOAuth2RequestHandler)handler;

@end
