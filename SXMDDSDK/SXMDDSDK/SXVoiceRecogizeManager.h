//
//  CCVoiceRecogizeManager.h
//  QuqiClass
//
//  Created by lishi on 2019/11/20.
//  Copyright © 2020 SpeechX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@class SXVoiceRecogizeManager;
@protocol SXVoiceRecogizeManagerDelegate <NSObject>


/// 调用结束录制返回结果
/// @param manager 管理器
/// @param mddDic 语音纠错返回的结果字典
/// @param filepath 录制后的文件路径。目前录音文件以mp3形式，保存在document文件夹下。
-(void)voiceRecogizeManager:(SXVoiceRecogizeManager *)manager didFinishedRecord:(NSDictionary *)mddDic andFilepath:(NSString *)filepath;


/// 录音时用户的音量大小反馈
/// @param manager 管理器
/// @param volume 音量百分比，可以用来显示录音波动效果
-(void)voiceRecogizeManager:(SXVoiceRecogizeManager *)manager didRecord:(float)volume;


/// 上传每个包的过程中是否出现错误，上传流程在status和description打印状态
/// @param manager 管理器
/// @param status 错误码 ：10000-正常流程 10001--未设置token 10002--写入流失败 10003-写入流缺省  10004-服务器返回异常 10005-录音组件异常 10006-监听音量组件异常
/// @param description 描述
-(void)voiceRecogizeManager:(SXVoiceRecogizeManager *)manager didUpload:(int)status description:(NSString *)description;



@end



@interface SXVoiceRecogizeManager : NSObject

@property (nonatomic, weak) id<SXVoiceRecogizeManagerDelegate>delegate;


+(instancetype)instance;


/// 设置token
/// @param token 校验密匙,需要在appdelegate didfinishedlaunch中设置token
-(void)setAppToken:(NSString *)token;


/// 开启流录制音频,
/// @param content 评测的内容
/// @param userid  用户id，可不传，用于在服务端创建用户id文件夹，不传则统一放在gu001
-(void)startRecordContent:(NSString *)content userid:(NSString *)userid;


/// 结束录制
-(void)stopRecord;


/// 是否在录制
-(BOOL)isRecording;



@end

NS_ASSUME_NONNULL_END
