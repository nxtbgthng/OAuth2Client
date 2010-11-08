//
//  NXOAuth2Connection.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NXOAuth2PostBodyStream.h"
#import "NXOAuth2PostBodyStreamMonitorDelegate.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2Client.h"
#import "NXOAuth2AccessToken.h"

#import "NXOAuth2Connection.h"

@interface NXOAuth2Client (Private)
- (void)removeConnectionFromWaitingQueue:(NXOAuth2Connection *)connection;
@end



@interface NXOAuth2Connection () <NXOAuth2PostBodyStreamMonitorDelegate>
- (NSURLConnection *)createConnection;
@end


@implementation NXOAuth2Connection

#pragma mark Lifecycle

#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
- (id)initWithRequest:(NSURLRequest *)aRequest
		  oauthClient:(NXOAuth2Client *)aClient
               finish:(void (^)(void))finishBlock 
                 fail:(void (^)(NSError *error))failBlock;
{
    if ([self initWithRequest:aRequest oauthClient:aClient delegate:nil]) {
        finish = Block_copy(finishBlock);
        fail = Block_copy(failBlock);
    }
    return self;
}
#endif

- (id)initWithRequest:(NSURLRequest *)aRequest
		  oauthClient:(NXOAuth2Client *)aClient
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate;
{
	if (self = [super init]) {
		sentConnectionDidEndNotification = NO;
		delegate = aDelegate;	// assign only
		client = [aClient retain];
		
		request = [aRequest copy];
		connection = [[self createConnection] retain];
	}
	return self;
}

- (void)dealloc;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
    Block_release(fail);
    Block_release(finish);
#endif
	[data release];
	[client release];
	[connection cancel];
	[connection release];
	[response release];
	[request release];
	[context release];
	[userInfo release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize delegate;
@synthesize data;
@synthesize context, userInfo;

- (NSInteger)statusCode;
{
	NSHTTPURLResponse *httpResponse = nil;
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		httpResponse = (NSHTTPURLResponse *)response;
	return httpResponse.statusCode;
}

- (long long)expectedContentLength;
{
	return response.expectedContentLength;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"NXOAuth2Connection <%@>", request.URL];
}

#pragma mark Public

- (void)cancel;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	[connection cancel];
	[client removeConnectionFromWaitingQueue:self];
}

- (void)retry;
{
	[response release]; response = nil;
	[connection cancel]; [connection release];
	connection = [[self createConnection] retain];
}


#pragma mark Private

- (NSURLConnection *)createConnection;
{
	NSMutableURLRequest *startRequest = [[request mutableCopy] autorelease];
	
	if (client.accessToken) {
		[startRequest setValue:[NSString stringWithFormat:@"OAuth %@", client.accessToken.accessToken]
			forHTTPHeaderField:@"Authorization"];
	}
	
	if (client.userAgent && ![startRequest valueForHTTPHeaderField:@"User-Agent"]) {
		[startRequest setValue:client.userAgent
			forHTTPHeaderField:@"User-Agent"];
	}
	
	NSInputStream *bodyStream = [startRequest HTTPBodyStream];
	if ([bodyStream isKindOfClass:[NXOAuth2PostBodyStream class]]){
		[(NXOAuth2PostBodyStream *)bodyStream setMonitorDelegate:self];
	}
	
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:startRequest delegate:self startImmediately:NO];	// don't start yet
	[aConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];	// let's first schedule it in the current runloop. (see http://github.com/soundcloud/cocoa-api-wrapper/issues#issue/2 )
	[aConnection start];	// now start
	
	if (!sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidStartConnection object:self];
	sentConnectionDidEndNotification = YES;
	
	return [aConnection autorelease];
}


#pragma mark -
#pragma mark SCPostBodyStream Delegate

- (void)stream:(NXOAuth2PostBodyStream *)stream didSendBytes:(unsigned long long)deliveredBytes ofTotal:(unsigned long long)totalBytes;
{
	if ([delegate respondsToSelector:@selector(oauthConnection:didSendBytes:ofTotal:)]){
		[delegate oauthConnection:self didSendBytes:deliveredBytes ofTotal:totalBytes];
	}
}


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)theResponse;
{
	NSAssert(response == nil, @"invalid state");
	[response release];	// just to be sure, should be nil already
	response = [theResponse retain];
	
	if (!data) {
		data = [[NSMutableData alloc] init];
	} else {
		[data setLength:0];
	}
	
	NSString *authenticateHeader = nil;
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSDictionary *headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
		for (NSString *headerKey in headerFields.allKeys) {
			if ([[headerKey lowercaseString] isEqualToString:@"www-authenticate"]) {
				authenticateHeader = [headerFields objectForKey:headerKey];
				break;
			}
		}
	}
	if (/*self.statusCode == 401 // TODO: check for status code once the bug returning 500 is fixed
		&&*/ client.accessToken.refreshToken != nil
		&& authenticateHeader
		&& [authenticateHeader rangeOfString:@"expired_token"].location != NSNotFound) {
		[self cancel];
		[client refreshAccessTokenAndRetryConnection:self];
	} else {
		if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
			[delegate oauthConnection:self didReceiveData:data];	// inform the delegate that we start with empty data
		}
		if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveResponse:)]) {
			[delegate oauthConnection:self didReceiveResponse:theResponse];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData;
{
	[data appendData:someData];
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
		[delegate oauthConnection:self didReceiveData:someData];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	if(self.statusCode < 400) {
		if ([delegate respondsToSelector:@selector(oauthConnection:didFinishWithData:)]) {
			[delegate oauthConnection:self didFinishWithData:data];
		}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
        if (finish) finish();
#endif
	} else {
		if (self.statusCode == 401) {
			// check if token is still valid
			NSString *authenticateHeader = nil;
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSDictionary *headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
				for (NSString *headerKey in headerFields.allKeys) {
					if ([[headerKey lowercaseString] isEqualToString:@"www-authenticate"]) {
						authenticateHeader = [headerFields objectForKey:headerKey];
						break;
					}
				}
			}
			if (authenticateHeader
				&& [authenticateHeader rangeOfString:@"invalid_token"].location != NSNotFound) {
				client.accessToken = nil;
			}
		}
		
		NSString *localizedError = [NSString stringWithFormat:NSLocalizedString(@"HTTP Error: %d", @"NXOAuth2HTTPErrorDomain description"), self.statusCode];
		NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObject:localizedError forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:NXOAuth2HTTPErrorDomain
												 code:self.statusCode
											 userInfo:errorUserInfo];
		if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
			[delegate oauthConnection:self didFailWithError:error];
		}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
        if (fail) fail(error);
#endif
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
		[delegate oauthConnection:self didFailWithError:error];
	}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
    if (fail) fail(error);
#endif
}

- (NSURLRequest *)connection:(NSURLConnection *)aConnection willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)aRedirectResponse;
{
	if (!aRedirectResponse) return aRequest; // if not redirecting do nothing
	
	BOOL hostChanged = [aRequest.URL.host caseInsensitiveCompare:aRedirectResponse.URL.host] != NSOrderedSame;
	
	BOOL schemeChanged = [aRequest.URL.scheme caseInsensitiveCompare:aRedirectResponse.URL.scheme] != NSOrderedSame;
	BOOL schemeChangedToHTTPS = schemeChanged && ([aRedirectResponse.URL.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame);
	
	if(hostChanged
	   || (schemeChanged && !schemeChangedToHTTPS)) {
		NSMutableURLRequest *mutableRequest = [[aRequest mutableCopy] autorelease];
		[mutableRequest setValue:nil forHTTPHeaderField:@"Authorization"]; // strip Authorization information
		return mutableRequest;
	}
	return aRequest;
}

#if TARGET_OS_IPHONE
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		//if ([trustedHosts containsObject:challenge.protectionSpace.host])
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
#endif

@end
