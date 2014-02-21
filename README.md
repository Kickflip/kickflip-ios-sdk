# Kickflip SDK for iOS

**note**: This is a pre-release API preview.

The [Kickflip](http://kickflip.io) platform provides a complete video broadcasting solution for your iOS application. You can use our pre-built `KFBroadcastViewController` to stream live video to your Kickflip account starting with one line of code.

## Quickstart

Launch Kickflip's default `KFBroadcastViewController` to instantly stream live video from your application:

```objc
[Kickflip setupWithAPIKey:@"API_KEY" secret:@"API_SECRET"];
[Kickflip presentBroadcasterFromViewController:self ready:^(NSURL *streamURL, NSError *error){ 
    if (streamURL) {
    	NSLog(@"Stream is ready to view at URL: %@", streamURL);
    }
} 
completion:nil];
```
	
	
## License

Apache 2.0

	Copyright 2014 OpenWatch, Inc.
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
	    http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.