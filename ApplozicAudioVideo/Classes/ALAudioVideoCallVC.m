//
//  ALAudioVideoCallVC.m
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/9/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALAudioVideoCallVC.h"
#import "ALCallKitManager.h"
#import <SDWebImage/SDWebImage.h>

NSString * const AL_CALL_DIALED = @"CALL_DIALED";
NSString * const AL_CALL_ANSWERED = @"CALL_ANSWERED";
NSString * const AL_CALL_REJECTED = @"CALL_REJECTED";
NSString * const AL_CALL_MISSED = @"CALL_MISSED";
NSString * const AL_CALL_END = @"CALL_END";

@interface ALAudioVideoCallVC ()

@property (weak, nonatomic) NSTimer * timer;
@property (weak, nonatomic) NSTimer * audioTimer;
@property (strong, nonatomic) NSString * callDuration;
@property (nonatomic) BOOL isTokenFetchingInProgress;
@property(strong) ALReachability * internetConnectionReach;

@end

@implementation ALAudioVideoCallVC
{
    BOOL buttonHide;
    BOOL speakerEnable;
    BOOL micEnable;
    BOOL frontCameraEnable;
    int count;
    NSDate *startDate;
    SystemSoundID soundID;
    NSString *soundPath;
    UITapGestureRecognizer *tapGesture;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNotificationObservers];
    [ALAudioVideoBaseVC setChatRoomEngage:YES];
    self.receiverID = self.userID;
    if (self.callForAudio) {
        speakerEnable = NO;
        [self setAudioOutputSpeaker:speakerEnable];
    } else {
        speakerEnable = YES;
        [self setAudioOutputSpeaker:speakerEnable];
    }


    UIImage *loudSpeakerImage = [self getImageWithImageName:speakerEnable ? @"volume_up_white.png" : @"volume_down_white.png"];
    [self.loudSpeaker setImage:loudSpeakerImage forState:UIControlStateNormal];
    self.internetConnectionReach = [ALReachability reachabilityForInternetConnection];
    [self.internetConnectionReach startNotifier];
    
    self.alMQTTObject = [ALMQTTConversationService sharedInstance];
    [self.alMQTTObject subscribeToConversation];
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    self.accessToken = @"TWILIO_ACCESS_TOKEN";
    
    self.tokenUrl = [NSString stringWithFormat:@"%@/twilio/token",[ALUserDefaultsHandler getBASEURL]];
    
    [self startPreview];
    
    if ([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_RECEIVED]]){
        [self fetchAccessTokenAndConnectToRoom];
    }
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animate)];
    
    buttonHide = NO;
    frontCameraEnable = NO;
    micEnable = NO;
    self.audioTimerLabel.text = @"";
}

-(void)setupNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)
                                                 name:AL_kReachabilityChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.userProfile.layer.cornerRadius = self.userProfile.frame.size.width/2;
        self.userProfile.layer.masksToBounds = YES;
    });
    
    [self.UserDisplayName setText:self.displayName];
    if (self.imageURL.length)
    {
        [self.userProfile sd_setImageWithURL:[NSURL URLWithString:self.imageURL]
                            placeholderImage:[self getImageWithImageName:@"ic_contact_picture_holo_light.png"]];
    }
    
    [self.callAcceptReject setHidden:YES];
    self.roomID = self.baseRoomId;
    count = 0;
    [self buttonVisiblityForCallType:NO];
    if([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
    {
        /// When calling to user will show status as Calling.
        NSString * callingStatusInfo = NSLocalizedStringWithDefaultValue(@"ALCallingStatusInfo", nil,[NSBundle mainBundle], @"Calling", @"");
        [self showCallStatus:YES withCallStatusInfo:callingStatusInfo];
        [self handleCallButtonVisiblity]; //  WHEN SOMEONE IS CALLING
        [self fetchAccessTokenAndConnectToRoom];
        soundPath = [[NSURL URLWithString:@"/System/Library/Audio/UISounds/nano/ringback_tone_aus.caf"] path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    }
    else
    {
        /// On the receiver end once the call is clicked for answering will show Connecting status.
        NSString * connectingStatusInfo = NSLocalizedStringWithDefaultValue(@"ALCallConnectingStatusInfo", nil,[NSBundle mainBundle], @"Connecting...", @"");
        [self showCallStatus:YES withCallStatusInfo:connectingStatusInfo];
        [self handleCallButtonVisiblity];
    }
    
    [self.audioCallType setHidden:NO];
    [self.audioCallType setTextColor: [UIColor whiteColor]];
    if (self.callForAudio) {
        self.audioCallType.text = [self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]] ?NSLocalizedStringWithDefaultValue(@"callAudioOutgoing", nil,[NSBundle mainBundle], @"Outgoing audio call", @""): NSLocalizedStringWithDefaultValue(@"callAudioIncoming", nil,[NSBundle mainBundle], @"Incoming audio call", @"");
    } else {
        self.audioCallType.text = [self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]] ?NSLocalizedStringWithDefaultValue(@"callVideoOutgoing", nil,[NSBundle mainBundle], @"Outgoing video call", @""): NSLocalizedStringWithDefaultValue(@"callVideoIncoming", nil,[NSBundle mainBundle], @"Incoming video call", @"");
        
    }
    [self.previewView setHidden:YES];
    [ALAudioVideoBaseVC setChatRoomEngage:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.alMQTTObject unsubscribeToConversation];
    [ALAudioVideoBaseVC setChatRoomEngage:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NETWORK_DISCONNECTED" object:nil];
}

-(void)dismissAVViewController:(BOOL)animated
{
    [super dismissAVViewController:animated];
    [self.timer invalidate];
    AudioServicesDisposeSystemSoundID(soundID);
    [self.room disconnect];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_VOIP_MSG" object:nil];
}

//==============================================================================================================================
#pragma mark BUTTON ACTIONS
//==============================================================================================================================

- (IBAction)toggleVideoShare:(id)sender {
    
    if (self.localVideoTrack.enabled)
    {
        [self.videoShare setImage:[self getImageWithImageName:@"videocam_off_white.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.videoShare setImage:[self getImageWithImageName:@"videocam_white.png"] forState:UIControlStateNormal];
    }
    self.localVideoTrack.enabled = !self.localVideoTrack.enabled;
}

- (IBAction)callAcceptRejectAction:(id)sender {
    [self callRejectAction:sender];
}

- (IBAction)callAcceptAction:(id)sender
{
    if(count < 60)
    {
        AudioServicesDisposeSystemSoundID(soundID);
        [self.timer invalidate];
    }
    [self fetchAccessTokenAndConnectToRoom];
    [self handleCallButtonVisiblity]; // WHEN SOMEONE IS ACCEPTING CALL
    [self buttonVisiblityForCallType:NO];
    [self.callView addGestureRecognizer:tapGesture];
}

- (IBAction)callRejectAction:(id)sender
{
    if (self.callForAudio) {
        [self.audioTimer invalidate];
    }
    
    ALCallKitManager * callkitManager = [ALCallKitManager sharedManager];
    [callkitManager performEndCallAction:self.uuid
                          withCompletion:^(NSError *error) {
    }];
}

- (IBAction)loudSpeakerAction:(id)sender
{
    if (!speakerEnable)
    {
        speakerEnable = YES;
        [self setAudioOutputSpeaker:YES];
        [self.loudSpeaker setImage:[self getImageWithImageName:@"volume_up_white.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self setAudioOutputSpeaker:NO];
        speakerEnable = NO;
        [self.loudSpeaker setImage:[self getImageWithImageName:@"volume_down_white.png"]  forState:UIControlStateNormal];
    }
}

- (IBAction)micMuteAction:(id)sender {
    [self muteCall];
}

-(void)muteCall {
    if (self.localAudioTrack)
    {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        
        if (self.localAudioTrack.isEnabled)
        {
            [self.muteUnmute setImage:[self getImageWithImageName:@"mic_white.png"]  forState:UIControlStateNormal];
        }
        else
        {
            [self.muteUnmute setImage:[self getImageWithImageName:@"mic_off_white.png"] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)cameraToggleAction:(id)sender
{
    if (!frontCameraEnable)
    {
        frontCameraEnable = YES;
        [self.cameraToggle setImage:[self getImageWithImageName:@"switch_camera_white.png"] forState:UIControlStateNormal];
    }
    else
    {
        frontCameraEnable = NO;
        [self.cameraToggle setImage:[self getImageWithImageName:@"outline_switch_camera_white.png"] forState:UIControlStateNormal];
    }
    [self flipCamera];
}

-(void)animate
{
    if(!buttonHide)
    {
        buttonHide = YES;
    }
    else
    {
        buttonHide = NO;
    }
    [ALUIUtilityClass movementAnimation:self.muteUnmute andHide:buttonHide];
    [ALUIUtilityClass movementAnimation:self.loudSpeaker andHide:buttonHide];
    if (!self.callForAudio)
    {
        [ALUIUtilityClass movementAnimation:self.cameraToggle andHide:buttonHide];
        [ALUIUtilityClass movementAnimation:self.videoShare andHide:buttonHide];
    }
}

-(void)playRingtone
{
    NSLog(@"COUNT :: %i",count);
    if (count > 60)
    {
        [self.timer invalidate];
        AudioServicesDisposeSystemSoundID(soundID);
        
        if ([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
        {
            // SELF IS CALLED/RECEIVER AND TIMEOUT (count > 60) : SEND MISSED MSG
            
            NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_MISSED
                                                                         andCallAudio:self.callForAudio
                                                                            andRoomId:self.roomID];
            [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                 andReceiverId:self.receiverID
                                                andContentType:AV_CALL_HIDDEN_NOTIFICATION
                                                    andMsgText:self.roomID withCompletion:^(NSError *error) {
                [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                     andReceiverId:self.receiverID
                                                    andContentType:AV_CALL_MESSAGE
                                                        andMsgText:@"CALL MISSED" withCompletion:^(NSError *error) {
                    [self.room disconnect];
                }];
            }];
        }
    }
    count = count + 3;
    AudioServicesPlaySystemSound(soundID);
}

-(void)timerForAudioCall:(NSTimer *)timer
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval elapsedTime = [currentDate timeIntervalSinceDate:startDate];
    NSInteger hours = elapsedTime / 3600;
    NSInteger minutes = elapsedTime / 60;
    NSInteger seconds = ((int)elapsedTime) % 60;
    [self.audioCallType setHidden:YES];
    self.audioTimerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
}

-(void)startAudioTimer
{
    // FOR AUDIO CALL WHEN SESSION STARTS IN BETWEEN THEM
    startDate = [NSDate date];
    self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(timerForAudioCall:)
                                                     userInfo:nil
                                                      repeats:YES];
}

-(void)handleCallButtonVisiblity
{
    [self.callReject setHidden:YES];
    [self.callAccept setHidden:YES];
    [self.callAcceptReject setHidden:NO];
}

-(void)buttonVisiblityForCallType:(BOOL)flag
{
    [self.muteUnmute setHidden:flag];
    [self.loudSpeaker setHidden:flag];
    if (self.callForAudio)
    {
        [self.cameraToggle setHidden:self.callForAudio];
        [self.videoShare setHidden:self.callForAudio];
    }
    else
    {
        [self.cameraToggle setHidden:flag];
        [self.videoShare setHidden:flag];
    }
}

// Show and hide views based on show flag and call status info
-(void) showCallStatus:(BOOL) show withCallStatusInfo:(NSString *)callStatusInfo {
    [self.callStatus setHidden:!show];
    if (callStatusInfo) {
        self.callStatus.text = callStatusInfo;
        /// Hide profile View and call type and only show the call status view in case of video call.
        if (!self.callForAudio &&
            self.remoteParticipant) {
            [self.callView setHidden:NO];
            self.callView.backgroundColor = [UIColor clearColor];
            [self.userProfile setHidden:YES];
            [self.audioCallType setHidden:YES];
        }
    }
    /// Hide the audio timer label in case of audio call
    if (self.callForAudio) {
        [self.audioTimerLabel setHidden:show];
    }
}

//==============================================================================================================================
#pragma mark - TWILIO : Public
//==============================================================================================================================

- (void)fetchAccessTokenAndConnectToRoom
{
    [self showRoomUI:YES];
    
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"])
    {
        self.isTokenFetchingInProgress = YES;
        [self logMessage:[NSString stringWithFormat:@"Fetching an access token"]];
        [ALAudioVideoUtils retrieveAccessTokenFromURL:self.tokenUrl completion:^(NSString *token, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isTokenFetchingInProgress = NO;
                if (!err)
                {
                    self.accessToken = token;
                    [self processConnection];
                }
                else
                {
                    [self logMessage:[NSString stringWithFormat:@"Error retrieving the access token"]];
                    [self showRoomUI:NO];
                }
            });
        }];
    } else {
        [self doConnect];
    }
}

-(void)processConnection
{
    if([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
    {
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_DIALED
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        [self doConnect];
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_HIDDEN_NOTIFICATION
                                                andMsgText:self.roomID withCompletion:^(NSError *error) {
            
        }];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                      target:self
                                                    selector:@selector(playRingtone)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    else
    {
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_ANSWERED
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        [self doConnect];
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_HIDDEN_NOTIFICATION
                                                andMsgText:self.roomID withCompletion:^(NSError *error) {
            
        }];
        
    }
}

//==============================================================================================================================
#pragma mark - TWILIO : Private
//==============================================================================================================================

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
    if (TARGET_OS_SIMULATOR)
    {
        
        NSLog(@"Video is not supported " );
        
        [self.previewView removeFromSuperview];
        return;
    }
    
    AVCaptureDevice *frontCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    AVCaptureDevice *backCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    if (frontCamera != nil || backCamera != nil) {
        self.camera = [[TVICameraSource alloc] initWithDelegate:self];
        self.localVideoTrack = [TVILocalVideoTrack trackWithSource:self.camera
                                                           enabled:YES
                                                              name:@"Camera"];
        if (!self.localVideoTrack) {
            [self logMessage:@"Failed to add video track"];
        } else {
            [self.localVideoTrack addRenderer:self.previewView];
            [self logMessage:@"Video track created"];
            
            if (frontCamera != nil && backCamera != nil) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(flipCamera)];
                [self.previewView addGestureRecognizer:tap];
            }
            
            [self.camera startCaptureWithDevice:frontCamera != nil ? frontCamera : backCamera completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
                if (error != nil) {
                    [self logMessage:[NSString stringWithFormat:@"Error selecting capture device.\ncode = %lu error = %@", error.code, error.localizedDescription]];
                } else {
                    self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
                }
            }];
        }
        
    } else {
        [self logMessage:@"No front or back capture device found!"];
    }
}

- (void)flipCamera {
    
    AVCaptureDevice *newDevice = nil;
    if (self.camera.device.position == AVCaptureDevicePositionFront) {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    } else {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    }
    if (newDevice) {
        [self.camera selectCaptureDevice:newDevice completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
            if (error != nil) {
                [self logMessage:[NSString stringWithFormat:@"Error selecting capture device.\ncode = %lu error = %@", error.code, error.localizedDescription]];
            } else {
                self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
            }
        }];
    }
}

- (void)prepareLocalMedia {
    // We will share local audio and video when we connect to room.
    
    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack trackWithOptions:nil
                                                            enabled:YES
                                                               name:@"Microphone"];
        
        if (!self.localAudioTrack) {
            [self logMessage:@"Failed to add audio track"];
        }
    }
    
    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect {
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"]) {
        [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }
    
    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];
    
    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
        
        // Use the local media that we prepared earlier.
        builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
        builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
        
        // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
        // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
        builder.roomName = self.roomID;
        builder.uuid = self.uuid;
    }];
    
    // Connect to the Room using the options we provided.
    self.room = [TwilioVideoSDK connectWithOptions:connectOptions delegate:self];
    
    [self logMessage:[NSString stringWithFormat:@"Attempting to connect to room %@", self.room.name]];
    
}


// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom
{
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)cleanupRemoteParticipant {
    
    if (self.remoteParticipant) {
        if (!self.callForAudio &&
            [self.remoteParticipant.videoTracks count] > 0) {
            TVIRemoteVideoTrack *videoTrack = self.remoteParticipant.remoteVideoTracks[0].remoteTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.remoteParticipant = nil;
    }
}

- (void)logMessage:(NSString *)msg
{
    NSLog(@"LOG_MESSAGE : %@",msg);
}

//==============================================================================================================================
#pragma mark - TVIRoomDelegate : PARTICIPANT : CONNECT/DISCONNECT
//==============================================================================================================================

- (void)didConnectToRoom:(TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    // HERE CURRENT USER CONNECTS TO ROOM
    
    [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    
    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
        self.remoteParticipant.delegate = self;
    }
    if (self.remoteParticipant) {
        // Hide the call status view when room is connected
        [self showCallStatus:NO withCallStatusInfo:nil];
        if (self.callForAudio) {
            [self startAudioTimer];
        } else {
            [self.previewView setHidden:NO];
        }
        [self.audioCallType setHidden:YES];
    }
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];
    
    // Show the call status when disconncted from room
    NSString * callEndStatusInfo = NSLocalizedStringWithDefaultValue(@"ALCallEndStatusInfo", nil,[NSBundle mainBundle], @"Call End", @"");
    [self showCallStatus:YES withCallStatusInfo:callEndStatusInfo];
    
    int reason = CXCallEndedReasonRemoteEnded;
    ALCallKitManager * callkitManager = [ALCallKitManager sharedManager];
    [callkitManager reportOutgoingCall:self.uuid withCXCallEndedReason:reason];
    
    [self cleanupRemoteParticipant];
    self.room = nil;
    [self showRoomUI:NO];
    [self clearRoom];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    
    self.room = nil;
    [self showRoomUI:NO];
}

- (void)room:(TVIRoom *)room isReconnectingWithError:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"Reconnecting due to %@", error.localizedDescription];
    [self logMessage:message];
    // Show the reconnecting to room
    NSString * callReconnectingStatusInfo = NSLocalizedStringWithDefaultValue(@"ALReconnectingCallStatusInfo", nil,[NSBundle mainBundle], @"Reconnecting...", @"");
    [self showCallStatus:YES withCallStatusInfo:callReconnectingStatusInfo];
}

- (void)didReconnectToRoom:(TVIRoom *)room {
    [self logMessage:@"Reconnected to room"];
    // Hide the call status view on room reconnected
    [self showCallStatus:NO withCallStatusInfo:nil];
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    
    // HERE RECEIVER USER CONNECT
    if (!self.remoteParticipant) {
        self.remoteParticipant = participant;
        self.remoteParticipant.delegate = self;
    }
    // Hide the call status view when participant connected
    [self showCallStatus:NO withCallStatusInfo:nil];
    
    ALCallKitManager * callkitManager = [ALCallKitManager sharedManager];
    [callkitManager reportOutgoingCall:self.uuid];
    
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ connected", room.name, participant.identity]];
    
    if(count < 60)
    {
        AudioServicesDisposeSystemSoundID(soundID);
        [self.timer invalidate];
        [self buttonVisiblityForCallType:NO];
        [self.remoteView addGestureRecognizer:tapGesture];
        
        // FOR AUDIO CALL
        if (self.callForAudio)
        {
            [self startAudioTimer];
        }
        else
        {
            [self.previewView setHidden:NO];
        }
    }
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    
    // HERE RECEIVER USER DIS-CONNECT
    if (self.remoteParticipant == participant) {
        [self cleanupRemoteParticipant];
        [self.room disconnect];
    }
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
}

#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
     didPublishVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has offered to share the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
   didUnpublishVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
     didPublishAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has offered to share the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
   didUnpublishAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didSubscribeToVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                     publication:(TVIRemoteVideoTrackPublication *)publication
                  forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    // Setup the remote view only in case of video call
    if (!self.callForAudio &&
        self.remoteParticipant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)didUnsubscribeFromVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                         publication:(TVIRemoteVideoTrackPublication *)publication
                      forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    // Remove the remote view only in case of video call
    if (!self.callForAudio &&
        self.remoteParticipant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)didSubscribeToAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                     publication:(TVIRemoteAudioTrackPublication *)publication
                  forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
}

- (void)didUnsubscribeFromAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                         publication:(TVIRemoteAudioTrackPublication *)publication
                      forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",publication.trackName, participant.identity]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      didEnableVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
     didDisableVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      didEnableAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
     didDisableAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToAudioTrack:(TVIRemoteAudioTrackPublication *)publication
                                 error:(NSError *)error
                        forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToVideoTrack:(TVIRemoteVideoTrackPublication *)publication
                                 error:(NSError *)error
                        forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];
    
    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    remoteView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view insertSubview:remoteView atIndex:0];
    
    if(!self.callForAudio){
        [self.callView setHidden:YES];
    }
    self.remoteView = remoteView;
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:height];
}

- (void)dealloc {
    [self clearRoom];
}

-(void)clearRoom {
    if (self.audioTimer) {
        [self.audioTimer invalidate];
    }
    // We are done with camera
    if (self.camera) {
        [self.camera stopCapture];
    }
    if (self.timer) {
        [self.timer invalidate];
    }
    self.localAudioTrack = nil;
    self.localVideoTrack = nil;
    self.camera = nil;
    self.room = nil;
}

- (void)setAudioOutputSpeaker:(BOOL)enabled {
    ALCallKitManager * callKitManager = [ALCallKitManager sharedManager];
    [callKitManager setAudioOutputSpeaker:enabled];
}

-(void)disconnectRoom {
    if (self.room) {
        [self.room disconnect];
    }
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

#pragma mark - TVICameraSourceDelegate

- (void)cameraSource:(TVICameraSource *)source didFailWithError:(NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
}


-(void)reachabilityChanged:(NSNotification*)note {
    ALReachability * reach = [note object];
    
    if (reach == self.internetConnectionReach) {
        if ([reach isReachable]) {
            /// If the token is not genrated once the internt connect again try to fetch the token and connect to room
            if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"] &&
                !self.room &&
                !self.isTokenFetchingInProgress) {
                [self fetchAccessTokenAndConnectToRoom];
            }
        }
    }
}

-(UIImage *)getImageWithImageName:(NSString *)imageName {
    NSBundle * bundle = [NSBundle bundleForClass:ALAudioVideoCallVC.class];
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

@end
