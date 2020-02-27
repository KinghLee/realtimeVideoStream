//
//  CCVoiceRecogizeManager.m
//  QuqiClass
//
//  Created by lishi on 2019/11/20.
//  Copyright © 2019 李诗. All rights reserved.
//

#import "SXVoiceRecogizeManager.h"

#import "SXAudioRecorder.h"
#import "SXMp3RecordWriter.h"
#import "SXAudioMeterObserver.h"
#import "SXVoiceUploader.h"
#import <AVKit/AVKit.h>


@interface SXVoiceRecogizeManager ()<SXVoiceUploaderDelegate>

@property (nonatomic, strong) SXAudioRecorder *recorder;

@property (nonatomic, strong) SXMp3RecordWriter *mp3Writer;

@property (nonatomic, strong) SXAudioMeterObserver *meterObserver;

@property (nonatomic, strong) SXVoiceUploader *uploadLoader;

@property(nonatomic,copy)NSString *token;

@property(nonatomic,copy)NSString *mp3FilePath;

@end

@implementation SXVoiceRecogizeManager

+(instancetype)instance{
    static SXVoiceRecogizeManager *m = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [SXVoiceRecogizeManager new];
        [m initComponent];
    });
    return m;
}

-(void)setAppToken:(NSString *)token{
    self.token = token;
}

-(void)dealloc{
    self.meterObserver.audioQueue = nil;
    [self.recorder stopRecording];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}

-(void)initComponent{
    __weak typeof(self) weakSelf = self;
    
    // 1.写入器
    SXMp3RecordWriter *mp3Writer = [[SXMp3RecordWriter alloc]init];
//    mp3Writer.filePath = self.mp3FilePath;
    mp3Writer.maxSecondCount = 60;
    mp3Writer.maxFileSize = 1024*256;
    self.mp3Writer = mp3Writer;
    
    // 2.监听音量大小组件
    SXAudioMeterObserver *meterObserver = [[SXAudioMeterObserver alloc]init];
    meterObserver.actionBlock = ^(NSArray *levelMeterStates,SXAudioMeterObserver *meterObserver){
//                NSLog(@"volume:%f",[SXAudioMeterObserver volumeForLevelMeterStates:levelMeterStates]);
        if (weakSelf.delegate) {
            [weakSelf.delegate voiceRecogizeManager:weakSelf didRecord:[SXAudioMeterObserver volumeForLevelMeterStates:levelMeterStates]];
        }
    };
    meterObserver.errorBlock = ^(NSError *error,SXAudioMeterObserver *meterObserver){
        if (weakSelf.delegate) {
            [weakSelf.delegate voiceRecogizeManager:weakSelf didUpload:10006 description:error.userInfo[NSLocalizedDescriptionKey]];
        }
    };
    self.meterObserver = meterObserver;
    
    // 3.录音器
    SXAudioRecorder *recorder = [[SXAudioRecorder alloc]init];
    recorder.receiveStoppedBlock = ^{
        weakSelf.meterObserver.audioQueue = nil;
    };
    recorder.receiveErrorBlock = ^(NSError *error){
        weakSelf.meterObserver.audioQueue = nil;
        
        if (weakSelf.delegate) {
            [weakSelf.delegate voiceRecogizeManager:weakSelf didUpload:10005 description:error.userInfo[NSLocalizedDescriptionKey]];
        }
    };
    recorder.fileWriterDelegate = mp3Writer;
    self.recorder = recorder;
    
    // 4.流上传器
    self.uploadLoader = [SXVoiceUploader new];
    self.uploadLoader.delegate = self;
    
    // 5.同级传数据用弱引用
    self.mp3Writer.uploadLoader = self.uploadLoader;
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChangeInterruptionType:)
                                                 name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
}

-(void)startRecordContent:(NSString *)content userid:(NSString *)userid{
    
    if (!self.token) {
        if (self.delegate) {
            [self.delegate voiceRecogizeManager:self didUpload:10001 description:@"未设置  token"];
        }
        return;
    }
    
    self.uploadLoader.token = self.token;
    self.uploadLoader.userid = userid;
    
    // 1.文件存储路径
    content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_]+" options:0 error:nil];
    content = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"-"];
    NSString *path =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSString *mp3path = [NSString stringWithFormat:@"/%@.mp3",content];
    self.mp3FilePath = [path stringByAppendingPathComponent:mp3path];
    self.mp3Writer.filePath = self.mp3FilePath;
    NSLog(@"%@",self.mp3FilePath);
    
    
    
    // 2.开启录制
    [self.recorder startRecording];
    self.meterObserver.audioQueue = self.recorder->_audioQueue;
    
    // 3.开始上传
    [self.uploadLoader connectSeverWithContent:content];
    
}

-(void)stopRecord{
    if ([self.recorder isRecording]) {
        [self.recorder stopRecording];
        [self.uploadLoader endUpload];
    }
}

-(BOOL)isRecording{
    return self.recorder.isRecording;
}



//MARK: -  SXVoiceUploaderDelegate
-(void)uploader:(SXVoiceUploader *)uploader didFinishUploadStreamAndGetResult:(NSDictionary *)dic{
    if (self.delegate) {
        [self.delegate voiceRecogizeManager:self didFinishedRecord:dic andFilepath:self.mp3FilePath];
    }
}

-(void)uploader:(SXVoiceUploader *)uploader didUploadStatus:(int)status description:(NSString *)description{
    if (self.delegate) {
        [self.delegate voiceRecogizeManager:self didUpload:status description:description];
    }
}



- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = [[[notification userInfo]
                                                        objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (AVAudioSessionInterruptionTypeBegan == interruptionType)
    {
        NSLog(@"begin");
    }
    else if (AVAudioSessionInterruptionTypeEnded == interruptionType)
    {
        NSLog(@"end");
    }
}





@end
