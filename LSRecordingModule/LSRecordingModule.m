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
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
//#import "Driver-Swift.h"
@implementation LSRecordingModule

+(instancetype)lsRecordingModuleShare{
    static LSRecordingModule *rescord = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rescord = [[LSRecordingModule alloc]init];
    });
    return rescord;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.session = [AVAudioSession sharedInstance];
        NSError *seeionError;
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&seeionError]; 
        if (_session ==  nil){
            NSLog(@"error creating session:%@ ",[seeionError description ]);
        }else{
            [_session setActive:YES error:nil];
        }
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}



// 接收录制中断事件通知，并处理相关事件
-(void)handleNotification:(NSNotification *)notification{
    NSArray *allKeys = notification.userInfo.allKeys;
    // 判断事件类型
    if([allKeys containsObject:AVAudioSessionInterruptionTypeKey]){
        AVAudioSessionInterruptionType audioInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        switch (audioInterruptionType) {
            case AVAudioSessionInterruptionTypeBegan:
                NSLog(@"录音被打断…… ");
                if ([self.recorder isRecording]){
                    [self stopRecording];
                }
                break;
            case AVAudioSessionInterruptionTypeEnded:
                NSLog(@"录音被打断…… 结束  可以返回代理 处理 上传业务");
                break;
        }
    }
    // 判断中断的音频录制是否可恢复录制
    if([allKeys containsObject:AVAudioSessionInterruptionOptionKey]){
        AVAudioSessionInterruptionOptions shouldResume = [[notification.userInfo valueForKey:AVAudioSessionInterruptionOptionKey] integerValue];
        if(shouldResume){
            NSLog(@"录音被打断…… 结束 可以恢复录音了");
            [self startRecording];
        }
    }
}
////设置录音配置
-(NSDictionary *)setRecord{
    NSDictionary *recordSetting =    @{AVFormatIDKey  :  @(kAudioFormatLinearPCM), //录音格式
                                       AVSampleRateKey : @(11025.0),              //采样率
                                       AVNumberOfChannelsKey : @2,                //通道数
                                       AVEncoderBitDepthHintKey : @16,            //比特率
                                       AVEncoderAudioQualityKey : @(AVAudioQualityHigh)}; //声音质量
    return  recordSetting;
}

-(void)setRecordingModeleMaxTimer:(NSInteger)recordingModeleMaxTimer{
    _recordingModeleMaxTimer = recordingModeleMaxTimer;
    self.countDown = recordingModeleMaxTimer;
}

///开始录音
-(void)startRecording{
    NSLog(@"开始录音");
    self.countDown = self.recordingModeleMaxTimer;
    [self getSavePath];
    self.recorder = [[AVAudioRecorder alloc]initWithURL:self.recordFileUrl settings:[self setRecord] error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    if ([_session respondsToSelector:@selector(requestRecordPermission:)]) {
        [_session requestRecordPermission:^(BOOL available) {
            if (available) {
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    printf("先打印通知 录音设置");
                    return ;
                });
            }
        }];
    }
    [self.recorder record];
    [self conn];
    [self addTimer];
}


-(void)conn{
    
    __weak typeof(self) weakself = self;
    [[ConvertAudioFile sharedInstance]conventToMp3WithCafFilePath:self.cafPath mp3FilePath:self.mp3Path sampleRate:ETRECORD_RATE callback:^(NSString *resultUrl, NSString *map3Url) {
        if ([weakself.delegate respondsToSelector:@selector(successMp3Url:)]){
            [weakself.delegate successMp3Url:map3Url];
            [weakself removeRecordingFile:resultUrl];
        }
        NSLog(@"%@",map3Url);
    }];
    
}
///创建录音地址
-(NSURL*)getSavePath{
    //  在Documents目录下创建一个名为FileData的文件夹
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"AudioData"];
    NSString *pathMp3 = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"AudioDataMP3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if(!(isDirExist && isDir)) {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",path);
    }
    
    BOOL isDir2 = FALSE;
    BOOL isDirExist2 = [fileManager fileExistsAtPath:pathMp3 isDirectory:&isDir2];
    if(!(isDirExist2 && isDir2)) {
        BOOL bCreateDir2 = [fileManager createDirectoryAtPath:pathMp3 withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir2){
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",pathMp3);
    }
    
    NSDateFormatter *format = [[NSDateFormatter alloc]init];
    format.dateFormat = @"yyyyMMDDHHmmss";
    NSString *timer = [format stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@",timer];
    
    NSString *cafFileName = [NSString stringWithFormat:@"%@.caf", fileName];
    NSString *mp3FileName = [NSString stringWithFormat:@"%@.mp3", fileName];
    
    self.cafPath = [path stringByAppendingPathComponent:cafFileName];
    self.mp3Path= [pathMp3 stringByAppendingPathComponent:mp3FileName];
    
    self.recordFileUrl = [NSURL fileURLWithPath:_cafPath];
    return  self.recordFileUrl;
}

//停止
-(void)stopRecording{
    [self removeTimer];
    [[ConvertAudioFile sharedInstance]sendEndRecord];
    [self.recorder stop];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.cafPath]){
        
        NSLog(@"%@",[NSString stringWithFormat:@"录了 %ld 秒,文件大小为 %.2fKb",self.recordingModeleMaxTimer - (long)self.countDown,[[manager attributesOfItemAtPath:self.cafPath error:nil] fileSize]/1024.0]);
        if ([[manager attributesOfItemAtPath:self.cafPath error:nil] fileSize]/1024.0 < 10 ){
            //            [self removeRecordingFile:self.mp3Path];
        }
    }
}

////删除  文件
- (void)removeRecordingFile:(NSString *)fileUrl {
    if (isValidString(fileUrl)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:fileUrl isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:fileUrl error:nil];
            NSLog(@"  %@ file  already delete",fileUrl);
        }
    }
}
///播放录音
-(void)playRecording{
    [self.recorder stop];
    NSLog(@"%@",self.mp3Path);
    self.player  = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:self.mp3Path] error:nil];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.player play];
}

/**
 *  添加定时器
 */
- (void)addTimer
{
    typeof(self) __weak wself = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    self.timer = timer;
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), NSEC_PER_SEC * 1, 0);
    dispatch_source_set_event_handler(timer, ^{
        if (wself.countDown > 0 ){
            wself.countDown --;
            NSLog(@"倒计时%ld",wself.countDown);
        }else{
            dispatch_source_cancel(wself.timer);
            [wself stopRecording];
            [wself startRecording];
        }
    });
    dispatch_resume(timer);
    
}
/**
 *  移除定时器
 */
- (void)removeTimer
{
    if (self.timer){
        dispatch_source_cancel(self.timer);
    } 
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"----- 录音  完毕");
    }
}

-(void)refreshLabelText{
    self.countDown --;
    if (self.countDown <= 0){
        [self stopRecording];
        [self startRecording];
    }
}
-(void)deleteAllFileManager{
    for (NSString *item in @[@"AudioData",@"AudioDataMP3"]) {
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:item];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(!(isDirExist && isDir)) {
            BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            if(!bCreateDir){
                NSLog(@"创建文件夹失败！");
            }
            NSLog(@"创建文件夹成功，文件路径%@",path);
        }else{
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    
}



@end
