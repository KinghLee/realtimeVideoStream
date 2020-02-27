//
//  CCVoiceUploader.m
//  QuqiClass
//
//  Created by lishi on 2020/2/13.
//  Copyright © 2020 李诗. All rights reserved.
//

#import "SXVoiceUploader.h"
#import "SXVoiceDataTask.h"


//#define voiceAuthToken @""

@interface SXVoiceUploader ()<NSURLSessionTaskDelegate,NSStreamDelegate>

@property(nonatomic,strong)NSURLSessionUploadTask *uploadTask;

@property(nonatomic,strong)NSOutputStream *outputStream;

@property(nonatomic,strong)NSInputStream *bodyStream;

@property(nonatomic,assign)BOOL isEnd;

@property(nonatomic,strong)NSMutableData *responseData;

@property(nonatomic,assign)BOOL hasSpaceAvailable;

@property(nonatomic,assign)BOOL isWriting;

@property(nonatomic,assign)int64_t alreadyRecord;

@property(nonatomic,assign)int64_t alreadyUpload;

@property(nonatomic,strong)NSTimer *timer;

@property(nonatomic,strong)NSMutableArray <SXVoiceDataTask *>*dataTaskArr;


@end

@implementation SXVoiceUploader



-(void)connectSeverWithContent:(NSString *)content{
    // 1.初始化
    _uploadTask = nil;
    _outputStream = nil;
    _bodyStream = nil;

    _isEnd = NO;
    _responseData = [NSMutableData data];
    _hasSpaceAvailable = NO;
    
    _alreadyRecord = 0;
    _alreadyUpload = 0;
    _dataTaskArr = [NSMutableArray new];

    
    // 2.配置参数
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];


    NSURL *r_url = [NSURL URLWithString:@"你的服务器地址"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:r_url];
    request.HTTPMethod = @"POST";
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    request.timeoutInterval = 30;

    // 设置请求头
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [request setValue:self.token forHTTPHeaderField:@"Authorization"];
    [request setValue:content forHTTPHeaderField:@"word_name"];
    [request setValue:@"stream.wav" forHTTPHeaderField:@"myWavfile"];
    [request setValue:self.userid?:@"gu001" forHTTPHeaderField:@"user_id"];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithStreamedRequest:request];
    self.uploadTask = uploadTask;


    // 3.任务执行
    [uploadTask resume];

    [self startTaskScaner];

}


-(void)uploadData:(NSData *)data{
    
    _alreadyRecord += [data length];
    
    SXVoiceDataTask *task = [SXVoiceDataTask new];
    task.data = data;
    task.hasUpload = NO;
    [_dataTaskArr addObject:task];
    
}


-(void)endUpload{
    _isEnd = YES;
}

-(void)stopStream{
//    NSLog(@"将要关闭流传输");
    self.outputStream.delegate = nil;
    [self.outputStream close];
}


-(void)add:(NSString *)str toData:(NSMutableData *)data{
    [data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

// MARK:NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler{
    
    // 绑定输入输出流
    
    NSInputStream *inputStream = nil;
    NSOutputStream *outputStream = nil;
    [NSStream getBoundStreamsWithBufferSize:8000*16 inputStream:&inputStream outputStream:&outputStream];
    
    self.bodyStream = inputStream;
    
    self.outputStream = outputStream;
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    completionHandler(self.bodyStream);
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    NSString *logStr = [NSString stringWithFormat: @"SXMDDSDK=>已上传：%lld,总上传:%lld，期望上传:%lld",bytesSent,totalBytesSent,totalBytesExpectedToSend];
    if (self.delegate) {
        [self.delegate uploader:self didUploadStatus:10000 description:logStr];
    }
    
    _alreadyUpload += bytesSent;
    
    if (_isEnd && _alreadyRecord == totalBytesSent) {
        
        
        [self stopTaskScaner];
        [self stopStream];
       
//        NSLog(@"上传完毕");
    }
}


// 以下三个方法收到数据
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    if (res.statusCode != 200) {
        
        NSString *dis = [NSString stringWithFormat:@"SXMDDSDK=>获取结果失败   %@",res.description];
        if (self.delegate) {
            [self.delegate uploader:self didUploadStatus:10004 description:dis];
            [self.delegate uploader:self didFinishUploadStreamAndGetResult:@{}];
        }
    }else{
        NSString *dis = @"SXMDDSDK=>获取结果成功";
        if (self.delegate) {
            [self.delegate uploader:self didUploadStatus:10000 description:dis];
        }
        completionHandler(NSURLSessionResponseAllow);
    }
    
}


-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    NSString *dis =  [NSString stringWithFormat:@"SXMDDSDK=>已经录制数据：%lld,已经上传数据：%lld",_alreadyRecord,_alreadyUpload];
    if (self.delegate) {
        [self.delegate uploader:self didUploadStatus:10000 description:dis];
    }
//    NSLog(@"%@",dis);
    
    //拼接数据
    [self.responseData appendData:data];
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    
    //解析数据
    NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
//    NSLog(@"%@",response);
    NSData *jsondata = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:jsondata options:0 error:nil];
    if (self.delegate) {
        [self.delegate uploader:self didFinishUploadStreamAndGetResult:json];
    }
    // 关闭任务
    [self stopTaskScaner];
}


// MARK: NSStreamDelegate

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;

        case NSStreamEventOpenCompleted:
           
            NSLog(@"NSStreamEventOpenCompleted");
            break;

        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            
            
        } break;

        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"NSStreamEventHasSpaceAvailable");
            _hasSpaceAvailable = YES;
            
        } break;

        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;

        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            break;

        default:
            break;
    }
}

//MARK: - 上传任务系统
-(void)startTaskScaner{
    if (self.timer==nil) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(scanTask) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
}

-(void)scanTask{
//    NSLog(@"扫描任务");
    if (_dataTaskArr.count == 0) {
        // 没有录音数据到来，等待
    }else{
        if (!_hasSpaceAvailable) {
            // 如果没有上传空间，则等待
        }else{
            // 遍历任务数组,找到第一个没完成的任务
            SXVoiceDataTask *task = nil;
            for (int i = 0; i<_dataTaskArr.count; i++) {
                if (!_dataTaskArr[i].hasUpload) {
                    task = _dataTaskArr[i];
                }
            }
            
            if (task != nil) {
                
                if (_isWriting) {
                    return;
                }
                _isWriting = YES;
                
                NSUInteger len = [task.data length];
                Byte *byteData = (Byte *)malloc(len);
                memcpy(byteData, [task.data bytes], len);
                
                NSUInteger ret = [self.outputStream write:byteData maxLength:len];
                if (ret <0) {
                    NSString *logStr =  @"SXMDDSDK=>写入流失败";
                    if (self.delegate) {
                        [self.delegate uploader:self didUploadStatus:10002 description:logStr];
                    }
                    _isWriting = NO;
                    return;
                }
                if (ret != len) {
                    NSString *logStr = [NSString stringWithFormat:@"SXMDDSDK=>写入流缺省,写入：%zd,需写入%zd",ret,len];
                    if (self.delegate) {
                        [self.delegate uploader:self didUploadStatus:10003 description:logStr];
                    }
                    
                    _isWriting = NO;
                    return;
                }
                NSString *logStr = [NSString stringWithFormat:@"SXMDDSDK=>写入流成功%zd",len];
                if (self.delegate) {
                    [self.delegate uploader:self didUploadStatus:10000 description:logStr];
                }
                task.hasUpload = YES;// 标记为已上传
                
                _isWriting = NO;
                _hasSpaceAvailable = false;
                
            }else{
                // 如果当前任务列表所有任务都完成，则不处理
                
            }
            
        }
    }
    
}

-(void)dealloc{
    [self stopTaskScaner];
}


-(void)stopTaskScaner{
    if (self.timer) {
        if ([self.timer respondsToSelector:@selector(isValid)]) {
            if ([self.timer isValid]) {
                [self.timer invalidate];
                self.timer = nil;
            }
        }
    }
}

@end
