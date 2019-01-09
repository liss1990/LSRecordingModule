//
//  ViewController.m
//  LSRecordingModule
//
//  Created by 李丝思 on 2018/10/26.
//  Copyright © 2018 李丝思. All rights reserved.
//

#import "ViewController.h"
#import "LSRecordingModule.h"
@interface ViewController ()<LSRecordingModuleDeleglate>
@property (weak, nonatomic) IBOutlet UILabel *showTime;
@property (nonatomic,strong)LSRecordingModule *recordingModule;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordingModule = [[LSRecordingModule alloc]init];
    self.recordingModule.recordingModeleMaxTimer = 60;
    self.recordingModule.delegate = self;
}
#pragma mark LSRecordingModuleDeleglate
-(void)downnTimer:(NSString *)timerString{
    self.showTime.text = [NSString stringWithFormat:@"还剩下 %@ 秒",timerString];
}

 

- (IBAction)startRecording:(UIButton *)sender {
    NSLog(@"开始录音");
    [self.recordingModule startRecording];
}

- (IBAction)stopRecording:(UIButton *)sender {
    [self.recordingModule stopRecording];
}


- (IBAction)playRecording:(UIButton *)sender {
    NSLog(@"播放录音");
    [self.recordingModule playRecording];
}
 

@end
