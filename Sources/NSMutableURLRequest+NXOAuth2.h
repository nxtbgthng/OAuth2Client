//
//  NSMutableURLRequest+NXOAuth2.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 07.10.09.
//
//  Copyright 2010 nxtbgthng. All rights reserved. 
//
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NSMutableURLRequest (NXOAuth2)

- (NSDictionary *)parameters;
- (void)setParameters:(NSDictionary *)parameters;

@end
