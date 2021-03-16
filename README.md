## Applozic iOS Audio Video SDK 

This project is a Cocoapods sample project for Audio-Video calls with messaging SDK.
The AppLozic Audio-Video Call SDK provides high quality IP audio and video calls. With this SDK, your application's users can take part in secure 1-to-1 calls.

## Overview

Applozic brings real-time engagement with chat, video, and voice to your web,
mobile, and conversational apps. We power emerging startups and established
companies with the most scalable and powerful chat APIs, enabling application
product teams to drive better user engagement, and reduce time-to-market.

Customers and developers from over 50+ countries use us and love us, from online
marketplaces and eCommerce to on-demand services, to Education Tech, Health
Tech, Gaming, Live-Streaming, and more.

Our feature-rich product includes robust client-side SDKs for iOS, Android, React
Native, and Flutter. We also support popular server-side languages, a beautifully
customizable UI kit, and flexible platform APIs.

Chat, video, and audio-calling have become the new norm in the post-COVID era,
and we're bridging the gap between businesses and customers by delivering those
exact solutions.


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

**NOTE:** You can run the sample in the simulator but
* Real-time call notification won't work in a simulator as it required the real-time VOIP notification to get the call notification you need to use an iPhone device. 
* Local video will not be shared since the Simulator cannot access a camera.

## Project Status

It's beta SDK

## Requirements

- Install the following:

  * Xcode 12.0 or later
  * CocoaPods 1.9.0 or later

- Make sure that your project meets these requirements:

  * Your project must target iOS 11 or later.

- Set up a physical iOS device to run your app

## Setup 

Signup at https://www.applozic.com/signup.html to get the App ID and you can use the same appID in ALChatManager.h file replace it with your App ID to this string value APPLICATION_ID.

## Installation

### Cocoapods 
ApplozicAudioVideo is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following lines to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs'
use_frameworks!  # Required to add 
platform :ios, '11.0'

target 'TARGET_NAME' do
    pod 'ApplozicAudioVideo'  # Required to add 
end
```
And go to your project directory where Podfile there run `pod install` from terminal


`Note:` The Audio-Video Call SDK includes our messaging SDK. If you have added ` pod 'Applozic' ` in your Podfile please remove that.

### Add Permissions

App Store requires any app which accesses camera, contacts, gallery, location, a microphone to add the description of why does your app needs to access these features.

In the Info.plist file of your project. Please add the following permissions

```
 <key>NSCameraUsageDescription</key>
 <string>Allow Camera</string>
 <key>NSContactsUsageDescription</key>
 <string>Allow Contacts</string>
 <key>NSLocationWhenInUseUsageDescription</key>
 <string>Allow location sharing!!</string>
 <key>NSMicrophoneUsageDescription</key>
 <string>Allow MicroPhone</string>
 <key>NSPhotoLibraryUsageDescription</key>
 <string>Allow Photos</string>
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>Allow write access</string>
 <key>NSLocalNetworkUsageDescription</key>
 <string>Allow LocalNetwork</string>
```

## Integration Steps

### Follow basic integration steps:
Refer to the basic integration steps from authentication, launch the conversation from this [link](https://docs.applozic.com/docs/ios-chat-session#for-applozic-sdk-)

### Add Audio video configuration
Add below setting in ALChatManger.m's file in the method ALDefaultChatViewSettings.

```objc
[ALApplozicSettings setAudioVideoClassName:@"ALAudioVideoCallVC"];
[ALApplozicSettings setAudioVideoEnabled:YES];
```
### Push notification

#### Setting up APNs Certificates

Applozic sends the payload to Apple servers which then sends the Push notification to your user's device.

#### Creating APNs certificates

For Apple to send these notifications, would have to create an APNs certificate in your Apple developer account.

1. Visit this [link](https://developer.apple.com/account/resources/certificates/add), to create Apple Push Notification service SSL (Sandbox) i.e development certificate

   ![apns-development-certificate](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-development-certificate.png "apns-development-certificate")


2. Visit this [link](https://developer.apple.com/account/resources/certificates/add), to create Apple Push Notification service SSL (Sandbox & Production) i.e distribution certificate

   ![apns-distribution-certificate](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-distribution.png "apns-distribution-certificate")


Once the certificates are created you can download them and export the p12 files with password for development and distribution certificate either from Keychain Acess from Mac.  


#### Upload APNs Certificates

Upload your push notification certificates (mentioned above) to the Applozic console by referring to the below-given image.

Go to Applozic [console](https://console.applozic.com/settings/pushnotification) push notification section to upload the APNs development and distribution certificates

   ![apns-certificate-upload](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-certificate-upload.png
 "apns-certificate-upload")


#### Creating VOIP certificate

VOIP certificate is required for sending incoming call notification from applozic to your app

1. Visit this [link](https://developer.apple.com/account/resources/certificates/add), to create VoIP Services Certificate
  
  ![VOIP-certificate](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/VOIP-certificate.png "VOIP-certificate")
 
Once the certificate is created download that and export the p12 file with password from the downloaded certificate either from Keychain Acess from Mac.

and contact `support@applozic.com` via email for uploading this VOIP certificate as we dont have the option to upload this from the applozic console right now

#### Adding Capabilities to Your App

Add capabilities to configure app services from Apple, such as push notifications, Background modes

On the Xcode project’s Signing & Capabilities tab, Click (+ Capability) to add “Push Notifications”

Next Click (+ Capability) to add "Background modes" enable this below four options from Background modes

 * “Audio, AirPlay and Picture in Picture” 
 * "Voice over IP"
 * "Background fetch"
 * "Remote notifications"
 
Following screenshot would be of help.

![xcode-capability](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/xcode-capability.png
 "xcode-capability")
 
 
#### Configure the push notification in the Appdelegate file of your project.

Add the below imports in the Appdelegate file

```objc
#import <Applozic/Applozic.h>
#import <UserNotifications/UserNotifications.h>
#import <PushKit/PushKit.h>
#import <ApplozicAudioVideo/ALAudioVideoPushNotificationService.h>
#import <ApplozicAudioVideo/ALAudioVideoCallHandler.h>
```

##### Handling app launch on notification click and register remote notification for APNs and VOIP PushKit

Add the following code in AppDelegate class, this function will be called after the app launch to register for push notifications.

```objc

// UNUserNotificationCenterDelegate and PKPushRegistryDelegate are required for APNs and push kit call backs please add this delegate to your AppDelegate file 
@interface AppDelegate () <UNUserNotificationCenterDelegate, PKPushRegistryDelegate>

@end


// didFinishLaunchingWithOptions method of your app

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // checks wheather app version is updated/changed then makes server call setting VERSION_CODE
    [ALRegisterUserClientService isAppUpdated];

    // Register APNs and Push kit
    [self registerForNotification];

    // Register for Applozic notification tap actions and network change notifications
    ALAppLocalNotifications *localNotification = [ALAppLocalNotifications appLocalNotificationHandler];
    [localNotification dataConnectionNotificationHandler];
    [[ALAudioVideoCallHandler shared] dataConnectionNotificationHandler];

    // Override point for customization after application launch.
    NSLog(@"launchOptions: %@", launchOptions);
    if (launchOptions != nil) {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil) {
            NSLog(@"Launched from push notification: %@", dictionary);
            ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
            BOOL applozicProcessed = [pushNotificationService processPushNotification:dictionary updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];

            //IF not a appplozic notification, process it
            if (!applozicProcessed) {
                //Note: notification for app
            }
        }
    }

    return YES;
}

// Register APNs and Pushkit 
-(void)registerForNotification
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
     {
        if(!error)
        {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[UIApplication sharedApplication] registerForRemoteNotifications];  // required to get the app to do anything at all about push notifications
                NSLog(@"Push registration success." );
                
                /// Push kit Registry
                PKPushRegistry * pushKitVOIP = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
                pushKitVOIP.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
                pushKitVOIP.delegate = self;
            });
        }
        else
        {
            NSLog(@"Push registration FAILED" );
            NSLog(@"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
            NSLog(@"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
        }
    }];
}

```

#### Sending an APNs and VOIP device token to applozic server 

Add the below code in your Appdelegate file if any of these methods already exist then you can copy-paste the code from the below methods.

```Objc

// APNs device token sending to applozic
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"DEVICE_TOKEN :: %@", deviceToken);

    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSString *apnDeviceToken = hexToken;
    NSLog(@"APN_DEVICE_TOKEN :: %@", hexToken);

    if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
        return;
    }

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateAPNsOrVOIPDeviceToken:apnDeviceToken
                                          withApnTokenFlag:YES withCompletion:^(ALRegistrationResponse *response, NSError *error) {

    }];
}

// Pushkit VOIP token sending to applozic 
-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {

    NSLog(@"PUSHKIT : VOIP_TOKEN_DATA : %@",credentials.token);
    const unsigned *tokenBytes = [credentials.token bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSLog(@"PUSHKIT : VOIP_TOKEN : %@",hexToken);
    if ([[ALUserDefaultsHandler getVOIPDeviceToken] isEqualToString:hexToken]) {
        return;
    }

    NSLog(@"PUSHKIT : VOIP_TOKEN_UPDATE_CALL");
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateAPNsOrVOIPDeviceToken:hexToken
                                          withApnTokenFlag:NO withCompletion:^(ALRegistrationResponse *response, NSError *error) {

    }];
}

```
#### Receiving push notification

Once your app receives notification, pass it to the Applozic handler for chat notification processing.

```objc
// UNUserNotificationCenter delegates for chat
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification*)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"APNS willPresentNotification for userInfo: %@", userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler(UNNotificationPresentationOptionNone);
        return;
    }
    completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse* )response withCompletionHandler:(nonnull void (^)(void))completionHandler {


    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo =  response.notification.request.content.userInfo;
    NSLog(@"APNS didReceiveNotificationResponse for userInfo: %@", userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler();
        return;
    }
    completionHandler();
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{

    NSLog(@"RECEIVED_NOTIFICATION_WITH_COMPLETION :: %@", userInfo);
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    if ([pushNotificationService isApplozicNotification:userInfo]) {
        ALAudioVideoPushNotificationService * audioVideoPushNotificationService = [[ALAudioVideoPushNotificationService alloc] init];
        [audioVideoPushNotificationService processPushNotification:userInfo];
        [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

// PushKit delegate for VOIP call notification 
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void(^)(void))completion {

    NSLog(@"PUSHKIT : INCOMING VOIP NOTIFICATION : %@", payload.dictionaryPayload.description);

    ALAudioVideoPushNotificationService *pushNotificationService = [[ALAudioVideoPushNotificationService alloc] init];
    NSDictionary * userInfoPayload = payload.dictionaryPayload;
    if ([pushNotificationService isApplozicNotification:userInfoPayload]) {
        [pushNotificationService processPushNotification:userInfoPayload];
        completion();
        return;
    }
    completion();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[ALDBHandler sharedInstance] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    NSLog(@"APP_ENTER_IN_FOREGROUND");
    [application setApplicationIconBadgeNumber:0];
}

```
**NOTE:** Without push notifications set-up, calls won't work as call notification requires a VOIP notification. Please make sure the push notifications are set-up properly.


## License

ApplozicAudioVideo is available under a BSD 3-Clause. See [LICENSE](LICENSE) file for more information.
