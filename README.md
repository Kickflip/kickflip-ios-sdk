# Kickflip SDK for iOS

The [Kickflip](http://kickflip.io) platform provides a complete video broadcasting solution for your iOS application. You can use our pre-built `KFBroadcastViewController` to stream live video to your Kickflip account starting with one line of code. Check out our [Kickflip iOS SDK example](https://github.com/Kickflip/kickflip-ios-example) to get started.

## Quickstart

The quickest way to get started will be to fork the [Kickflip iOS SDK example](https://github.com/Kickflip/kickflip-ios-example). Launch Kickflip's default `KFBroadcastViewController` to instantly stream live video from your application:

```objc
#import "Kickflip.h"
// Call setup as soon as possible so your users can start streaming right away
[Kickflip setupWithAPIKey:@"API_KEY" secret:@"API_SECRET"];
...
- (void) broadcastButtonPressed:(id)sender {
	[Kickflip presentBroadcasterFromViewController:self ready:^(KFStream *stream) {
        if (stream.streamURL) {
            NSLog(@"Stream is ready at URL: %@", stream.streamURL);
        }
    } completion:^(BOOL success, NSError* error){
        if (!success) {
            NSLog(@"Error setting up stream: %@", error);
        } else {
            NSLog(@"Done broadcasting");
        }
    }];
}
```

## Cocoapods Setup

You'll need to install [Cocoapods](http://cocoapods.org) first.
    
Add the following line to your `Podfile`:

    pod 'Kickflip'

Then run Cocoapods to install all of the dependencies:

    $ pod install

As with all projects that depend on Cocoapods, make sure to open the new `.xcworkspace` file, not your `.xcodeproj` file.
    
## Documentation

For a closer look at what you do with Kickflip, check out our [iOS Documentation](https://github.com/Kickflip/kickflip-docs/tree/master/ios) and [iOS API Reference](http://cocoadocs.org/docsets/Kickflip/). We also have some [tutorials](https://github.com/Kickflip/kickflip-docs) to help you get started.
    
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