# Kickflip SDK for iOS

**note**: This is a pre-release API preview.

The [Kickflip](http://kickflip.io) platform provides a complete video broadcasting solution for your iOS application. You can use our pre-built `KFBroadcastViewController` to stream live video to your Kickflip account starting with one line of code.

## Quickstart

Launch Kickflip's default `KFBroadcastViewController` to instantly stream live video from your application:

    ```objc
	[Kickflip setupWithAPIKey:@"API_KEY" secret:@"API_SECRET"];
	[Kickflip presentBroadcastViewFromViewController:self ready:^(NSURL *streamURL, NSError *error){ 
	    if (streamURL) {
	    	NSLog(@"Stream is ready to view at URL: %@", streamURL);
	    }
	} 
	completion:nil];
	```
	
	
## License

MIT