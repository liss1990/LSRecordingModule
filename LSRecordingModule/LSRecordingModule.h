//
//  LSRecordingModule.h
//  luyinDemo
//
//  Created by 李丝思 on 2018/10/25.
//  Copyright © 2018 李丝思. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol LSRecordingModuleDeleglate <NSObject>

-(void)downnTimer:(NSString *)timerString;

@end

@interface LSRecordingModule : NSObject<AVAudioRecorderDelegate>
@property(nonatomic,strong)NSTimer *timer;
@property(nonatomic,copy) NSString *mp3Path;
@property(nonatomic,copy) NSString *cafPath;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;//录音器
@property (nonatomic, strong) AVAudioPlayer *player; //播放器
@property (nonatomic, strong) NSURL *recordFileUrl; //文件地址
///录音的最大时限。分钟
@property(nonatomic,assign)NSInteger recordingModeleMaxTimer;
///录音的倒计时
@property(nonatomic,assign)NSInteger countDown;
@property(nonatomic,weak)id<LSRecordingModuleDeleglate> delegate;

///开始录音
-(void)startRecording;
//停止录音
-(void)stopRecording; 
//移除本地录音
-(void)removeRecordingMP3Data;
///播放录音
-(void)playRecording;

@end
 
