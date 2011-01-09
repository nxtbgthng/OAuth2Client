//
//  NXOAuth2URLRequest.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 10.12.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NXOAuth2URLRequest : NSMutableURLRequest {
	NSDictionary	*parameters;
}

@property (nonatomic, retain) NSDictionary *parameters;

- (void)resetHTTPBodyStream;

@end
