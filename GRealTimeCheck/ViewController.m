//
//  ViewController.m
//  GTimeCheck
//
//  Created by guohx on 2019/6/14.
//  Copyright © 2019 ghx. All rights reserved.
//

#import "ViewController.h"

#import "GRealTimeUtil.h"

@interface ViewController () {
    UILabel * realTimeLab;
    UILabel * sysTimeLab;
    UILabel *  offsetTimeLab;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setUp];
    [self createUI];
}

- (void)setUp {
    [GRealTimeUtil shareInstance].noNetToNetNeedUpdateTime = YES;

    [[GRealTimeUtil shareInstance] networkStatusChange:^(ReachabilityStatus status) {
        if (status == RealStatusNotReachable) {

            NSLog(@"routerReachability NotReachable");
        } else if (status == RealStatusViaWiFi) {

            NSLog(@"routerReachability ReachableViaWiFi");

        } else if (status == RealStatusViaWWAN) {

            NSLog(@"routerReachability ReachableViaWWAN");

        }
    }];

    NSTimer * repeatingTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.3]
                                                        interval:1
                                                          target:self
                                                        selector:@selector(refreshData)
                                                        userInfo:nil
                                                         repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:repeatingTimer
                                 forMode:NSRunLoopCommonModes];
}

- (void)createUI {
    CGSize mainSize = [UIScreen mainScreen].bounds.size;
    CGFloat space  = 10;

    sysTimeLab = [[UILabel alloc] initWithFrame:CGRectMake(space, 100, mainSize.width - 2*space, 50)];
    sysTimeLab.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:sysTimeLab];

    realTimeLab = [[UILabel alloc] initWithFrame:CGRectMake(space, 100 + 60, mainSize.width - 2*space, 50)];
    realTimeLab.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:realTimeLab];


    offsetTimeLab = [[UILabel alloc] initWithFrame:CGRectMake(space, 100 + 2*60, mainSize.width - 2*space, 50)];
    offsetTimeLab.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:offsetTimeLab];

    UIButton *  refreshBtn = [[UIButton alloc] initWithFrame:CGRectMake(space, 100 + 3*60, mainSize.width - 2*space, 50)];
    //    [refreshBtn setBackgroundImage:[UIImage imageNamed:@"btnBg.jpg"] forState:UIControlStateNormal];
    [refreshBtn setBackgroundColor:[UIColor brownColor]];
    [refreshBtn setTitle:@"校正" forState:UIControlStateNormal];
    [refreshBtn setTitle:@"校正中..." forState:UIControlStateHighlighted];
    [refreshBtn addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refreshBtn];

    realTimeLab.text = [NSString stringWithFormat:@"校准时间:%@",[GRealTimeUtil shareInstance].realDateStr];

    sysTimeLab.text = [NSString stringWithFormat:@"系统时间:%@",[GRealTimeUtil timeStrFromDate:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"]];

    NSTimeInterval offsetTime = [[GRealTimeUtil shareInstance] networkOffset];
    offsetTimeLab.text = [NSString stringWithFormat:@"偏移时间:%.0f",offsetTime*1000];
}


- (void)refreshData {

    realTimeLab.text = [NSString stringWithFormat:@"校准时间:%@",[GRealTimeUtil shareInstance].realDateStr];

    sysTimeLab.text = [NSString stringWithFormat:@"系统时间:%@",[GRealTimeUtil timeStrFromDate:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"]];

    NSTimeInterval offsetTime = [[GRealTimeUtil shareInstance] networkOffset];
    offsetTimeLab.text = [NSString stringWithFormat:@"偏移时间:%.0f",offsetTime*1000];

}


@end
