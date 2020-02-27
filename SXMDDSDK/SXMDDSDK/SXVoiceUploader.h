//
//  CCVoiceUploader.h
//  QuqiClass
//
//  Created by lishi on 2020/2/13.
//  Copyright © 2020 李诗. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SXVoiceUploader;
@protocol  SXVoiceUploaderDelegate<NSObject>

-(void)uploader:(SXVoiceUploader *)uploader didFinishUploadStreamAndGetResult:(NSDictionary *)dic;

-(void)uploader:(SXVoiceUploader *)uploader didUploadStatus:(int)status description:(NSString *)description;

@end


@interface SXVoiceUploader : NSObject

@property(nonatomic,weak)id <SXVoiceUploaderDelegate>delegate;

@property(nonatomic,copy)NSString *token;

@property(nonatomic,copy)NSString *userid;


-(void)connectSeverWithContent:(NSString *)content;

-(void)uploadData:(NSData *)data;

-(void)endUpload;


@end

NS_ASSUME_NONNULL_END
