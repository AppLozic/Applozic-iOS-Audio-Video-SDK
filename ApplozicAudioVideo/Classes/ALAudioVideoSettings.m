//
//  ALAudioVideoSettings.m
//  ApplozicAudioVideo
//
//  Created by Sunil on 01/02/21.
//

#import "ALAudioVideoSettings.h"

@implementation ALAudioVideoSettings

+(void)setCallKitAppIconName:(NSString*)appIconName {
    NSUserDefaults * userDefaults = ALAudioVideoSettings.getUserDefaults;
    [userDefaults setValue:appIconName forKey:AL_AUDIO_VIDEO_CALL_KIT_ICON_NAME_KEY];
    [userDefaults synchronize];
}

+(NSString*)getCallKitAppIconName {
    NSUserDefaults * userDefaults = ALAudioVideoSettings.getUserDefaults;
    NSString *callKitIconName = [userDefaults valueForKey:AL_AUDIO_VIDEO_CALL_KIT_ICON_NAME_KEY];
    return callKitIconName;
}

+(NSUserDefaults *)getUserDefaults{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.com.applozic.share"];
}

@end
