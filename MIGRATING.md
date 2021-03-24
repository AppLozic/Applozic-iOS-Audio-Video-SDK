## Migration Guides

#### Migrating from old version to new version 0.2.0 and above

##### Breaking changes:

1. Update ALChatManager files .m, .h or .swift and apply your customization settings or changes if you have added here are chat manager file

  Objective-c project:
  
* [ALChatManager.h](https://github.com/AppLozic/Applozic-iOS-Audio-Video-SDK/blob/main/Example/ApplozicAudioVideo/ALChatManager.h)
* [ALChatManager.m](https://github.com/AppLozic/Applozic-iOS-Audio-Video-SDK/blob/main/Example/ApplozicAudioVideo/ALChatManager.m)

Swift project:

[ALChatManager.swift](https://github.com/AppLozic/Applozic-iOS-Chat-Samples/blob/master/sampleapp-swift/sampleapp-swift/ALChatManager.swift)

Note: Make sure this configrature are added in your ALChatmanager file [link](https://docs.applozic.com/docs/ios-video-chat-and-audio-call-api#add-audio-video-configuration)

2.In `AppDelegate` file inside the method of  `didFinishLaunchingWithOptions`  paste the below settings code 

Objective-c

```objc
ALPushNotificationHandler *pushNotificationHandler = [ALPushNotificationHandler shared];
[pushNotificationHandler dataConnectionNotificationHandler];
```
Swift
```swift
let pushNotificationHandler = ALPushNotificationHandler.shared()
pushNotificationHandler.dataConnectionNotificationHandler()
```
