# realtimeVideoStream
##### 背景
网上有很多帖子写这个功能，但是大部分零零碎碎，没办法直接用。
本文把思路整理下，并且真正可用，有问题可以微信我(lishi_655)。
如果您觉得好请帮忙点个赞。Thanks♪(･ω･)ﾉ

##### 实现步骤：
1. 首先是边录边压缩录音流，参考代码[MLAudioRecorder](https://link.jianshu.com?t=http://code.cocoachina.com/view/125797)
。本文使用了其中的三个类：录音类MLAudioRecorder ，pcm转mp3类Mp3RecordWriter，音量大小监听类MLAudioMeterObserver。
2. 对获得的二进制录音流，使用我封装的CCVoiceUploader来上传流。关于上传的思路，网上有帖子写，例如[这篇](https://www.jianshu.com/p/44f382b74b18)，但是不完整，且有问题。Stack Overflow上的问答也没有可用的。流的传输还需要参考苹果论坛中[官方回复](https://forums.developer.apple.com/message/251792#251792)才能理解写法。苹果开发人员还是厉害。
3. 您需要基于1和2封装一个管理和错误处理类,即是这个sdk




