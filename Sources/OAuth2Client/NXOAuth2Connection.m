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
- (NSURLConnection *)createStartedConnectionWithRequest:(NSURLRequest *)aRequest connectionDelegate:(id)connectionDelegate streamDelegate:(id)streamDelegate;
@end


@implementation NXOAuth2Connection

#pragma mark Lifecycle

- (id)initWithRequest:(NSURLRequest *)aRequest
		  oauthClient:(NXOAuth2Client *)aClient
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate;
{
	if (self = [super init]) {
		statusCode = 0;
		expectedContentLength = 0;
		delegate = aDelegate;	// assign only
		client = [aClient retain];	// TODO: check if assign is better here
		
		request = [aRequest copy];
		connection = [self createStartedConnectionWithRequest:request connectionDelegate:self streamDelegate:self];
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
@synthesize expectedContentLength, statusCode;
@synthesize context, userInfo;


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
	[connection release];
	connection = [self createStartedConnectionWithRequest:request connectionDelegate:self streamDelegate:self];
}


#pragma mark Private

- (NSURLConnection *)createStartedConnectionWithRequest:(NSURLRequest *)aRequest connectionDelegate:(id)connectionDelegate streamDelegate:(id)streamDelegate;
{
	NSMutableURLRequest *startRequest = [[aRequest mutableCopy] autorelease];
	
	if (client.accessToken) {
		[startRequest setValue:client.accessToken.accessToken forHTTPHeaderField:@"Authorization"];
	}
	
	NSInputStream *bodyStream = [startRequest HTTPBodyStream];
	if ([bodyStream isKindOfClass:[NXOAuth2PostBodyStream class]]){
		[(NXOAuth2PostBodyStream *)bodyStream setMonitorDelegate:streamDelegate];
	}
	
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:startRequest delegate:connectionDelegate startImmediately:NO];	// don't start yet
	[aConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];				// let's first schedule it in the current runloop. (see http://github.com/soundcloud/cocoa-api-wrapper/issues#issue/2 )
	[aConnection start];	// now start
	return aConnection;
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	expectedContentLength = response.expectedContentLength;
	statusCode = [(NSHTTPURLResponse *)response statusCode];
	
	if (!data) {
		data = [[NSMutableData alloc] init];
	} else {
		[data setLength:0];
	}
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
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
	if(statusCode < 400) {
		if ([delegate respondsToSelector:@selector(oauthConnection:didFinishWithData:)]) {
			[delegate oauthConnection:self didFinishWithData:data];
		}
	} else {
		NSError *httpError = [NSError errorWithDomain:NSURLErrorDomain
												 code:statusCode
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													   [NSHTTPURLResponse localizedStringForStatusCode:statusCode], NSLocalizedDescriptionKey,
													   nil]];
		NSError *error = [NSError errorWithDomain:NXOAuth2ErrorDomain
											 code:NXOAuth2HTTPErrorCode
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   httpError, NXOAuth2HTTPErrorKey,
												   nil]];
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

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
	// TODO: handle request signed with expired token
}


@end
