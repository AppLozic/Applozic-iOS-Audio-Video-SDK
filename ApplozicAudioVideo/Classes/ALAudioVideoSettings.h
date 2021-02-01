//
//  ALAudioVideoSettings.h
//  ApplozicAudioVideo
//
//  Created by Sunil on 01/02/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const AL_AUDIO_VIDEO_CALL_KIT_ICON_NAME_KEY = @"com.applozic.userdefault.AL_AUDIO_VIDEO_CALL_KIT_ICON_NAME_KEY";

@interface ALAudioVideoSettings : NSObject

+(void)setCallKitAppIconName:(NSString*)appIconName;

+(NSString*)getCallKitAppIconName;
@end

NS_ASSUME_NONNULL_END
