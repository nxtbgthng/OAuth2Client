## Using the OAuth2Client

### Create an instance of NXOAuth2Client

To create an NXOAuth2Client instance you need OAuth2 credentials (client id & secret) and endpoints (authorize &
token URL) for your application. You usually get them from the service you want to connect to. You also need to
pass in an *delegate* which is discussed later.

<pre>
	// client is a ivar
	client = [[NXOAuth2Client alloc] initWithClientID:@"xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx"
									 	 clientSecret:@"xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx"
									 	 authorizeURL:[NSURL URLWithString:@"https://myHost/oauth2/authenticate"]
										 	 tokenURL:[NSURL URLWithString:@"https://myHost/oauth2/token"]
									 	 	 delegate:self];
</pre>

Once you got your instance of the client you can check if you already have a valid token.

<pre>
	[client requestAccess];
</pre>

This method triggers the authentication flow and will invoke one or more of the callback methods implemented in the clients delegate.


### The Delegate
<a name="TheDelegate"></a>
The Authentication Delegate is the place to get callbacks on the status of authentication. It defines following methods:

<pre>
@required
	- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;

@optional
	- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
	- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
	- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
</pre>

#### The optional delegate methods

The first three delegate methods inform you when authentication is gained or lost, as well as when an error occurred during the process.
`-oauthClientDidGetAccessToken:` for example is called when the authorization flow finishes with an access token or when your app was
authorized in a previous session and the access token has been found in the keychain.

`-oauthClientDidLoseAccessToken:` is called whenever the token is lost. This might be the case when the token expires and there has been
an error refreshing it, or when the user revokes access on the service your connecting to.

`-oauthClient:didFailToGetAccessTokenWithError:` returns the error that prevented the client from getting a valid access token. See the
constants header file (`NXOAuth2Constants.h`) and the [section about errors](http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-3.2.1)
in the OAuth2 spec for more information which errors to expect. Besides errors in the `NXOAuth2ErrorDomain` you should also handle NSURL errors
in the `NSURLErrorDomain`.

#### The required delegate method

The fourth method needs to be implemented by your app and is responsible for choosing the OAuth2 authorization flow. The wrapper supports
the user-agent & the user credentials flow of OAuth2 draft 10. The following two sections show you example implementations for both type of flows.


##### User-agent flow

In the user-agent flow your app opens an internal user-agent (an embedded web view) or an external user-agent (the default browser) to open a
site on the service your connecting to. The user enters his credentials and is redirected to an URL you define. This URL should open your
application or should be intercepted if you're using an internal web view. Pass this URL to the `-authorizationURLWithRedirectURL:` method
of your NXOAuth2Client instance, and it will get the access token out of it.

<pre>
- (void)oauthClientRequestedAuthorization:(NXOAuth2Client *)aClient;
{
	// webserver flow
	
	// this is your redirect url. register it with your app
	NSURL *authorizationURL = [client authorizationURLWithRedirectURL:[NSURL URLWithString:@"x-myapp://oauth2"]];
	#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] openURL:authorizationURL];	// this line quits the application or puts it to the background, be prepared
	#else
	[[NSWorkspace sharedWorkspace] openURL:authorizationURL];
	#endif
}
</pre>

##### User credentials flow

The user credentials flow allows your app do present the user a custom login form. Please consider that this flow is *generally discouraged*
since the user has to enter his credentials in an untrusted environment and can't control what your app does with the entrusted credentials.

<pre>
- (void)oauthClientRequestedAuthorization:(NXOAuth2Client *)aClient;
{
	// user credentials flow
	[client authorizeWithUsername:username password:password];
	// you probably don't yet have username & password.
	// if so, open a view to query them from the user & call this method with the results asynchronously.
}
</pre>

### Sending requests

Create your request as usual but don't use NSURLConnection but `NXOAuth2Connection`. It has a similar delegate protocol but signs the request
when an `NXOAuth2Client` is passed in. If you don't pass in the client but nil, the connection will work standalone but not sign any request. Make
sure to retain the connection for as long as it's running. The best place for doing so is it's delegate. You can also cancel the connection if
the delegate is deallocated.

<pre>
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://myHost/someResource"]];
	// retain the connection for as long as it's running.
	NXOAuth2Connection *connection = [[NXOAuth2Connection alloc] initWithRequest:request oauthClient:aClient delegate:self];
</pre>
