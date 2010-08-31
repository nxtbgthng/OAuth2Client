//
//  NXOAuth2Connection.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2PostBodyStream.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2Client.h"
#import "NXOAuth2AccessToken.h"

#import "NXOAuth2Connection.h"


@interface NXOAuth2Connection ()
+ (NSURLConnection *)startedConnectionWithRequest:(NSURLRequest *)aRequest connectionDelegate:(id)connectionDelegate streamDelegate:(id)streamDelegate client:(NXOAuth2Client *)theClient;
@end


@implementation NXOAuth2Connection

#pragma mark Lifecycle

- (id)initWithRequest:(NSURLRequest *)aRequest
		  oauthClient:(NXOAuth2Client *)aClient
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate;
{
	if (self = [super init]) {
		delegate = aDelegate;	// assign only
		client = [aClient retain];	// TODO: check if assign is better here
		
		request = [aRequest copy];
		connection = [[[self class] startedConnectionWithRequest:request connectionDelegate:self streamDelegate:self client:client] retain];
	}
	return self;
}

- (void)dealloc;
{
	[data release];
	[client release];
	[connection cancel];
	[connection release];
	[request release];
	[context release];
	[userInfo release];
	[super dealloc];
}


#pragma mark Accessors

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


#pragma mark Public

- (void)cancel;
{
	[connection cancel];
	// maybe unschedule from current runloop now?...
	[client abortRetryOfConnection:self];
}

- (void)retry;
{
	[self cancel];
	[response release]; response = nil;
	[connection release];
	connection = [[[self class] startedConnectionWithRequest:request connectionDelegate:self streamDelegate:self client:client] retain];
}


#pragma mark Private

+ (NSURLConnection *)startedConnectionWithRequest:(NSURLRequest *)aRequest connectionDelegate:(id)connectionDelegate streamDelegate:(id)streamDelegate client:(NXOAuth2Client *)theClient;
{
	NSMutableURLRequest *startRequest = [[aRequest mutableCopy] autorelease];
	
	if (theClient.accessToken) {
		[startRequest setValue:[NSString stringWithFormat:@"OAuth %@", theClient.accessToken.accessToken]
			forHTTPHeaderField:@"Authorization"];
	}
	
	NSInputStream *bodyStream = [startRequest HTTPBodyStream];
	if ([bodyStream isKindOfClass:[NXOAuth2PostBodyStream class]]){
		[(NXOAuth2PostBodyStream *)bodyStream setMonitorDelegate:streamDelegate];
	}
	
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:startRequest delegate:connectionDelegate startImmediately:NO];	// don't start yet
	[aConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];												// let's first schedule it in the current runloop. (see http://github.com/soundcloud/cocoa-api-wrapper/issues#issue/2 )
	[aConnection start];	// now start
	return [aConnection autorelease];
}


#pragma mark -
#pragma mark SCPostBodyStream Delegate

- (void)stream:(NXOAuth2PostBodyStream *)stream hasBytesDelivered:(unsigned long long)deliveredBytes total:(unsigned long long)totalBytes;
{
	if ([delegate respondsToSelector:@selector(oauthConnection:didSendBytes:ofTotal:)]){
		[delegate oauthConnection:self didSendBytes:deliveredBytes ofTotal:totalBytes];
	}
}


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)theResponse;
{
	NSAssert(response == nil, @"invalid state");
	[response release];	// just to be sure
	response = [theResponse retain];
	
	if (!data) {
		data = [[NSMutableData alloc] init];
	} else {
		[data setLength:0];
	}
	
	NSString *authenticateHeader = nil;
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		authenticateHeader = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"WWW-Authenticate"];
	if (self.statusCode == 401
		&& client.accessToken.refreshToken != nil
		&& [authenticateHeader rangeOfString:@"expired_token"].location != NSNotFound) {
		[self cancel];
		[client refreshAccessTokenAndRetryConnection:self];
	} else if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
		[delegate oauthConnection:self didReceiveData:data];	// inform the delegate that we start with empty data
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
	if(self.statusCode < 400) {
		if ([delegate respondsToSelector:@selector(oauthConnection:didFinishWithData:)]) {
			[delegate oauthConnection:self didFinishWithData:data];
		}
	} else {
		NSError *httpError = [NSError errorWithDomain:NSURLErrorDomain
												 code:self.statusCode
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													   [NSHTTPURLResponse localizedStringForStatusCode:self.statusCode], NSLocalizedDescriptionKey,
													   nil]];
		NSMutableDictionary *errorInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 httpError, NXOAuth2HTTPErrorKey,
										 nil];
		NSError *error = [NSError errorWithDomain:NXOAuth2ErrorDomain
											 code:NXOAuth2HTTPErrorCode
										 userInfo:errorInfo];
		if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
			[delegate oauthConnection:self didFailWithError:error];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)httpError;
{
	NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							   httpError, NXOAuth2HTTPErrorKey,
							   nil];
	NSError *error = [NSError errorWithDomain:NXOAuth2ErrorDomain
										 code:NXOAuth2HTTPErrorCode
									 userInfo:errorInfo];
	if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
		[delegate oauthConnection:self didFailWithError:error];
	}
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
	NSLog(@"Auth error: ", [challenge.error localizedDescription]);
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		//if ([trustedHosts containsObject:challenge.protectionSpace.host])
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end
