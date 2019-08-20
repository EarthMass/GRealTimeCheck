//
//  GRealTimeUtil.m
//  TimeCheckDemo
//
//  Created by guohx on 2019/4/12.
//  Copyright © 2019年 istrong. All rights reserved.
//

#import "GRealTimeUtil.h"
#include <sys/sysctl.h>
#import "ios-ntp.h"

#import <RealReachability/RealReachability.h>

static NSString * ntfAddress = @"time.apple.com";

@interface NewestNetTime : NSObject

@property (nonatomic, assign)  NSTimeInterval netTime; //服务器时间
@property (nonatomic, assign)  NSTimeInterval upTime; //当前设备运行时间

@end

@implementation NewestNetTime


@end

@interface GRealTimeUtil() <NetAssociationDelegate>

/** [这个是批量的地址，取最优，无回调]
 网络时钟发送网络时间通知。它将试图提供一个非常
 提前估计，然后改进并减少通知数量…γ
 //NetworkClock 默认读取 ntp.hosts 中的时间域名，也可调用createAssociationsWithServers:

 只需创建一个网络时钟。创建后，ntp进程将开始轮询“ntp.hosts”文件中的时间服务器。您可能希望在应用程序启动时启动它，以便时间与实际使用时间完全同步，只需在AppDelegate的DidFinishLaunching方法中调用它即可：
 NetworkClock * nc = [NetworkClock sharedNetworkClock];

 然后至少等待10秒钟，等待服务器响应，然后再调用：
 NSDate * nt = nc.networkTime;
 */
@property (nonatomic, strong) NetworkClock *  netClock;           // complex clock

/** [指定的域名，有回调] 0.几秒就可以获取到数据
 此网络关联管理一台服务器的通信和时间计算。 针对特定的 时间服务器
 在每个客户机/服务器对（关联）工作到的过程中使用多个服务器
 获得自己的最佳版本。客户端向服务器发送小的UDP包，然后
 服务器覆盖包中的某些字段，并立即返回。每包
 收到时，客户端网络时间和系统时钟之间的偏移量用导出。
 相关统计。
 */
@property (nonatomic, strong) NetAssociation *  netAssociation;     // one-time server

@property (nonatomic, strong) NewestNetTime * newestNetTime;

@property (nonatomic, copy) void(^netStatusBlock)(ReachabilityStatus status);

@end

@implementation GRealTimeUtil

+ (void)load {
    /**
     * 注册通知
     */
    __block id observer =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidFinishLaunchingNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification *note) {
         /**
          初始化操作
          */
         [[GRealTimeUtil shareInstance] beginCheckTime];
         //完成相关操作，注销通知
         [[NSNotificationCenter defaultCenter] removeObserver:observer];
     }];
}

+ (instancetype)shareInstance {
    static GRealTimeUtil * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{



        instance = [[GRealTimeUtil alloc] initUniqueInstance];

        instance.newestNetTime = [[NewestNetTime alloc] init];

        //网络监控
        [self beginNetReachableCheck];

        //时间比较久 返回
//        instance.netClock = [NetworkClock sharedNetworkClock];

        instance.netAssociation = [[NetAssociation alloc]
                          initWithServerName:[NetAssociation ipAddrFromName:ntfAddress]];
        instance.netAssociation.delegate = instance;
        [instance.netAssociation sendTimeQuery];

//         [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(updateRealTime) name:UIApplicationDidFinishLaunchingNotification object:nil];

//        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(updateRealTime) name:UIApplicationDidEnterBackgroundNotification object:nil];
//
//        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(updateRealTime) name:UIApplicationDidBecomeActiveNotification object:nil];

        //后台修改 回到 前台 时间改变，更新时间
        [[NSNotificationCenter defaultCenter]addObserver:instance selector:@selector(updateRealTime) name:UIApplicationSignificantTimeChangeNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:instance
                                                 selector:@selector(networkChanged:)
                                                     name:kRealReachabilityChangedNotification
                                                   object:nil];



    });
    return instance;
}

-(instancetype)initUniqueInstance {
    return [super init];
}

- (void)beginCheckTime {
    [self.netAssociation sendTimeQuery];
}

- (NSTimeInterval)networkOffset {

    NSTimeInterval offset = self.netAssociation.offset;
    if (offset == INFINITY) { //未取到
        return 0;
    }
    return offset;
//    NSTimeInterval offset = self.netClock.networkOffset;
//    if (self.netClock.trusty) {
//        return offset;
//    }
//    return 0;
}

- (NSDate *)realDate {

    if (![self networkReachable]) {
        //无网络情况
        if (self.newestNetTime.netTime) {
           NSTimeInterval currTimeInterval = self.newestNetTime.netTime + ([self uptime] - self.newestNetTime.upTime);
            return [NSDate dateWithTimeIntervalSince1970:currTimeInterval];
        } else {
            //一直无网络 以第一次的时间为基准
            self.newestNetTime.netTime = [[NSDate date] timeIntervalSince1970];
            self.newestNetTime.upTime = [self uptime];

            return [NSDate date];

        }
    } else {
        if (self.netAssociation.offset == INFINITY) {

            //无网络情况
            if (self.newestNetTime.netTime) {
                NSTimeInterval currTimeInterval = self.newestNetTime.netTime + ([self uptime] - self.newestNetTime.upTime);
                return [NSDate dateWithTimeIntervalSince1970:currTimeInterval];
            } else {
                //一直无网络 以第一次的时间为基准
                self.newestNetTime.netTime = [[NSDate date] timeIntervalSince1970];
                self.newestNetTime.upTime = [self uptime];

                return [NSDate date];

            }

        } else {

            NSDate * date = [[NSDate date] dateByAddingTimeInterval:-self.netAssociation.offset];
            self.newestNetTime.netTime = [date timeIntervalSince1970];
            self.newestNetTime.upTime = [self uptime];

            return date;

        }


    }

//    NSDate * date = self.netClock.networkTime;
//    NSLog(@"time is %@",date);
//    if (self.netClock.trusty) {
//
//        return date;
//    }
//    return [NSDate date];
}

- (NSString *)realDateStr {

    return [self realDateStrWithFormatterStr:@"yyyy-MM-dd HH:mm:ss"];

}

- (NSString *)realDateStrWithFormatterStr:(NSString *)formatterStr {

    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:formatterStr];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString * timeStr = [formatter stringFromDate:[self realDate]];
    return timeStr;
}

+ (NSString *)timeStrFromDate:(NSDate *)date formatter:(NSString *)formatterStr{

    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:formatterStr];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString * timeStr = [formatter stringFromDate:date];
    return timeStr;
}

+ (NSTimeInterval)timeStrToLongLongWithStr:(NSString *)timeStr formatter:(NSString *)formmater {

    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    [format setDateFormat:formmater];
    [format setTimeZone:[NSTimeZone localTimeZone]];
    NSDate * date = [format dateFromString:timeStr];
    return [date timeIntervalSince1970];
}

/**
 默认 yyyy-MM-dd HH:mm:ss
 */
+ (NSString *)timeStrFromLongDate:(long long)longTime {
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:longTime];
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [format setTimeZone:[NSTimeZone localTimeZone]];

    return [format stringFromDate:date];
}
+ (NSString *)timeStrFromLongDate:(long long)longTime formatter:(NSString *)formatterStr {
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:longTime];
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    [format setDateFormat:formatterStr];
    [format setTimeZone:[NSTimeZone localTimeZone]];

    return [format stringFromDate:date];
}

- (long long)realDateOrigin {

    NSDate * realDate = [self realDate];

    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone localTimeZone]];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:realDate];

    NSDate * originDate = [calendar dateFromComponents:components];
    return [originDate timeIntervalSince1970];
}

#pragma mark- 网络获取
- (void)reportFromDelegate {

#if DEBUG
    double timeOffset = self.netAssociation.offset;
    NSLog(@"%f",timeOffset);
    NSLog(@"原本时间：%@",[self.class timeStrFromDate:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"]);
    NSLog(@"校正时间：%@",[self realDateStrWithFormatterStr:@"yyyy-MM-dd HH:mm:ss"]);
#endif
}


#pragma mark- 退到后台回来
- (void)updateRealTime {

    if (self.netAssociation) {
        if (self.noNetToNetNeedUpdateTime) {
            self.netAssociation = [[NetAssociation alloc]
                                                            initWithServerName:[NetAssociation ipAddrFromName:ntfAddress]];
        }
        //call once
         [self.netAssociation sendTimeQuery];
    }
}



#pragma mark- 系统本地判断
/**
 上次系统启动的时间

 @return long时间
 */
- (long)bootTime {
#define MIB_SIZE 2

    int mib[MIB_SIZE];
    size_t size;
    struct timeval  boottime;

    mib[0] = CTL_KERN;
    mib[1] = KERN_BOOTTIME;
    size = sizeof(boottime);
    if (sysctl(mib, MIB_SIZE, &boottime, &size, NULL, 0) != -1)
    {
        return boottime.tv_sec;
    }
    return 0;
}

/**
 手机运行时长
 now是当前的时候，受本地系统时间的影响
 sysctl 获取的是上次设备重启的时间，也受本地系统时间的影响
 两者之差就是系统从上次设备重启之后所运行的时间

 @return time
 */
- (time_t)uptime {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    (void)time(&now);
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}


#pragma mark- 网络连接状态
+ (void)beginNetReachableCheck {

    [GLobalRealReachability startNotifier];
}

- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];

    if (self.netStatusBlock) {
        self.netStatusBlock(status);
    }

    if (status == RealStatusNotReachable) {

        NSLog(@"routerReachability NotReachable");
    } else if (status == RealStatusViaWiFi) {

        NSLog(@"routerReachability ReachableViaWiFi");
        [[GRealTimeUtil shareInstance] updateRealTime];
    } else if (status == RealStatusViaWWAN) {

        NSLog(@"routerReachability ReachableViaWWAN");
        [[GRealTimeUtil shareInstance] updateRealTime];
    }
}

- (void)networkStatusChange:(void(^)(ReachabilityStatus status))netStatusBlock {
    self.netStatusBlock = netStatusBlock;
}



-(BOOL)networkReachable {

   ReachabilityStatus status = [[RealReachability sharedInstance] currentReachabilityStatus];
    if (status == RealStatusNotReachable) {
        return NO;
    }
    return YES;
}

+ (NSTimeInterval)realDateTimeInterval {
    NSDate *date = [[GRealTimeUtil shareInstance] realDate];
    
    return [date timeIntervalSince1970];
}

@end



