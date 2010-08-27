//
//  NSMutableURLRequest+NXOAuth2.h
//  Soundcloud
//
//  Created by Ullrich Schäfer on 07.10.09.
//  Copyright 2009 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableURLRequest (NXOAuth2)

- (NSDictionary *)parameters;
- (void)setParameters:(NSDictionary *)parameters;

@end
