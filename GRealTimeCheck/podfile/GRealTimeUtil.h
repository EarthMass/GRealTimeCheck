//
//  GRealTimeUtil.h
//  TimeCheckDemo
//
//  Created by guohx on 2019/4/12.
//  Copyright © 2019年 istrong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RealReachability/RealReachability.h>

/*
 网络切换会报错
 dnssd_clientstub deliver_request: 没找到原因
 */

/* ntp
 需要联网校验一次  后台到前台，会调用，网络变化 会调用。
 如果无网络 无法校验

 无网络校验，以单次启动时间为准确时间。

 未联网校验过。【针对于单次执行，不缓存本地】

 本地校验时间，联网时间 + （开机时间间隔 -（联网校验的开机时间间隔））
 【不一定准确，如果没有联网，或者重新重启手机（没联网的情况）】
 */

#define GRealDate [GRealTimeUtil shareInstance] realDate]

@interface GRealTimeUtil : NSObject

- (instancetype)new __attribute__((unavailable("init not available, call sharedInstance instead")));//NS_UNAVAILABLE;
- (instancetype)init __attribute__((unavailable("init not available, call sharedInstance instead")));//NS_UNAVAILABLE;


/**
 无网络进入 网络变化->有网络  是否更新时间 默认NO 不更新
 */
@property (nonatomic, assign) BOOL noNetToNetNeedUpdateTime;

+ (instancetype)shareInstance;


/**
 执行一次 网络获取
 */
- (void)beginCheckTime;

/**
 有网络才有效
 @return 时间偏移
 */
- (NSTimeInterval)networkOffset;

- (void)networkStatusChange:(void(^)(ReachabilityStatus status))netStatusBlock;

- (NSDate *)realDate;
- (NSString *)realDateStr;
- (NSString *)realDateStrWithFormatterStr:(NSString *)formatter;

+ (NSString *)timeStrFromDate:(NSDate *)date formatter:(NSString *)formatterStr;

+ (NSTimeInterval)timeStrToLongLongWithStr:(NSString *)timeStr formatter:(NSString *)formmater;


/**
 默认 yyyy-MM-dd HH:mm:ss
 */
+ (NSString *)timeStrFromLongDate:(long long)longTime;
+ (NSString *)timeStrFromLongDate:(long long)longTime formatter:(NSString *)formatterStr;

/**
 当天时间

 @return 当天时间0点
 */
- (long long)realDateOrigin;

+ (NSTimeInterval)realDateTimeInterval;
    
@end

