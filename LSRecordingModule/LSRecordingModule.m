//
//  LSRecordingModule.m
//  luyinDemo
//
//  Created by 李丝思 on 2018/10/25.
//  Copyright © 2018 李丝思. All rights reserved.
//

#import "LSRecordingModule.h"
#import "ConvertAudioFile.h"
#define isValidString(string)               (string && [string isEqualToString:@""] == NO)
#define ETRECORD_RATE 11025.0
#define ENCODE_MP3    1



@implementation LSRecordingModule

-(void)setRecordingModeleMaxTimer:(NSInteger)recordingModeleMaxTimer{
    _recordingModeleMaxTimer = recordingModeleMaxTimer;
    self.countDown = recordingModeleMaxTimer;
}

///开始录音
-(void)startRecording{
    NSLog(@"开始录音");
    [self addTimer];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *seeionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&seeionError];
    if (session ==  nil){
        NSLog(@"error creating session:%@ ",[seeionError description ]);
    }else{
        [session setActive:YES error:nil];
    }
    
    self.session = session;
    self.recordFileUrl = [self getSavePath];
    NSDictionary *recordSetting = @{AVSampleRateKey:[NSNumber numberWithFloat:44100],
                                    AVFormatIDKey:[NSNumber numberWithInt:kAudioFormatLinearPCM],
                                    AVLinearPCMBitDepthKey:[NSNumber numberWithInt:16],
                                    AVNumberOfChannelsKey:[NSNumber numberWithInt:1],
                                    AVEncoderAudioQualityKey:[NSNumber numberWithInt:AVAudioQualityHigh]
                                    };
    self.recorder = [[AVAudioRecorder alloc]initWithURL:self.recordFileUrl settings:recordSetting error:nil];
    
    NSLog(@"%@",self.recorder);
    if (self.recorder) {
        self.recorder.delegate = self;
        self.recorder.meteringEnabled = YES;
        [self.recorder prepareToRecord];
        [self.recorder record];
        
 #if ENCODE_MP3
        [self convertMp3];
 #endif
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * 300 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopRecording];
        });
    }else{
       NSLog(@"音频格式和文件存储格式不匹配,无法初始化Recorder");
    }
}
- (void)convertMp3 {

    [[ConvertAudioFile sharedInstance] conventToMp3WithCafFilePath:self.cafPath     mp3FilePath:self.mp3Path sampleRate:ETRECORD_RATE callback:^(BOOL result)
     {
         NSLog(@"---- 转码完成  --- result %d  ---- ", result);
         if (result) {
             if (result) {
                 /////可以在这里操作 在转换完成后删掉本地的caf文件
             }
         }
     }];;
}
///创建录音地址
-(NSURL*)getSavePath{
    //  在Documents目录下创建一个名为FileData的文件夹
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"AudioData"];
    NSLog(@"%@",path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if(!(isDirExist && isDir))
        
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",path);
    }
    NSString *fileName = @"record";
    NSString *cafFileName = [NSString stringWithFormat:@"%@.caf", fileName];
    NSString *mp3FileName = [NSString stringWithFormat:@"%@.mp3", fileName];
    
    NSString *cafPath = [path stringByAppendingPathComponent:cafFileName];
    NSString *mp3Path = [path stringByAppendingPathComponent:mp3FileName];
    
    self.mp3Path = mp3Path;
    self.cafPath = cafPath;
    
    NSLog(@"file path:%@",cafPath);
    
    NSURL *url=[NSURL fileURLWithPath:cafPath];
    return url;
}

//停止录音
-(void)stopRecording{
    
    if ([self.recorder isRecording]){
        [self removeTimer];
        [self.recorder stop];
        [[ConvertAudioFile sharedInstance] sendEndRecord];
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.cafPath]){
        NSLog(@"%@",[NSString stringWithFormat:@"录了 %ld 秒,文件大小为 %.2fKb",self.recordingModeleMaxTimer - (long)self.countDown,[[manager attributesOfItemAtPath:self.cafPath error:nil] fileSize]/1024.0]);
    }else{
        NSLog(@"最多录%ld秒",(long)self.recordingModeleMaxTimer);
    }
    
    #if !ENCODE_MP3
        [self convertMp3];
    #endif
    
}

//移除本地mp3录音
-(void)removeRecordingMP3Data{
    if (isValidString(self.mp3Path)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:self.mp3Path isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:self.mp3Path error:nil];
            NSLog(@"  xxx.mp3Path  file   already delete");
        }
    }
}
////删除.caf 文件 保留 .mp3格式
- (void)removeRecordingCafFile {
    
    if (isValidString(self.cafPath)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:self.cafPath isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:self.cafPath error:nil];
            NSLog(@"  xxx.caf  file   already delete");
        }
    }
}
///播放录音
-(void)playRecording{
    [self.recorder stop];
    NSLog(@"%@",self.recordFileUrl);
    self.player  = [[AVAudioPlayer alloc]initWithContentsOfURL:self.recordFileUrl error:nil];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.player play];
}

/**
 *  添加定时器
 */
- (void)addTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshLabelText) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
/**
 *  移除定时器
 */
- (void)removeTimer
{
    [_timer invalidate];
    _timer = nil;
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"----- 录音  完毕");
#if ENCODE_MP3
        [[ConvertAudioFile sharedInstance] sendEndRecord];;
#endif
        
    }
}
-(void)refreshLabelText{
    self.countDown --;
    
    if ([self.delegate respondsToSelector:@selector(downnTimer:)]){
        [self.delegate downnTimer:[NSString stringWithFormat:@"%ld",self.countDown]];
    }
    
}
@end
