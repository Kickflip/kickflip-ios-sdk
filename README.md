# Kickflip SDK for iOS

The [Kickflip](http://kickflip.io) platform provides a complete video broadcasting solution for your iOS application. You can use our pre-built `KFBroadcastViewController` to stream live video to your Kickflip account starting with one line of code. Check out our [Kickflip iOS SDK example](https://github.com/Kickflip/kickflip-ios-example).

## Quickstart

The quickest way to get started will be to fork the [Kickflip iOS SDK example](https://github.com/Kickflip/kickflip-ios-example). Launch Kickflip's default `KFBroadcastViewController` to instantly stream live video from your application:

```objc
[Kickflip setupWithAPIKey:@"API_KEY" secret:@"API_SECRET"];
[Kickflip presentBroadcasterFromViewController:self ready:^(NSURL *streamURL, NSError *error){ 
    if (streamURL) {
    	NSLog(@"Stream is ready to view at URL: %@", streamURL);
    }
} 
completion:nil];
```

## Cocoapods Setup

You'll need to install [Cocoapods](http://cocoapods.org) first. We haven't submitted the SDK to Cocoapods yet, but it is available right now as a custom podspec so you can track development in the master branch.
    
Add the following to your `Podfile`:

    pod 'Kickflip', :git => 'https://github.com/Kickflip/kickflip-ios-sdk.git'
    
## Screenshots

[![kickflip app screenshot](https://i.imgur.com/QPtggd9m.jpg)](https://i.imgur.com/QPtggd9.png)
[![kickflip live broadcast screenshot](https://i.imgur.com/VHB6iQQm.jpg)](https://i.imgur.com/VHB6iQQ.png)
[![kickflip live consumption screenshot](https://i.imgur.com/IZbiyhRm.jpg)](https://i.imgur.com/IZbiyhR.png)

[Screenshots Gallery](http://imgur.com/a/IwuZ7)

    
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