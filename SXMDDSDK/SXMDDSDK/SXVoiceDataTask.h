//
//  CCVoiceDataTask.h
//  QuqiClass
//
//  Created by lishi on 2020/2/17.
//  Copyright © 2020 李诗. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SXVoiceDataTask : NSObject

@property(nonatomic,strong)NSData *data;

// 是否已上传
@property(nonatomic,assign)BOOL hasUpload;


@end

NS_ASSUME_NONNULL_END
