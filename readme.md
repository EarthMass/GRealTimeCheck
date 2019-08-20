# ntf时间校验工具
## 特点
- 有网络 时间校验
- 无网络时间校验，以首次调用时间为 标准时间。 开机时长计算校准。
- 无网络->有网络      是否需要校验。两种情况。
- 有网络 可以获取到时间 偏差，无网络 不行
- 加入了 网络监控，比如 一些应用必须使用到网络。
- 校验时机，后台到前台，网络变化。

# 集成
```
pod 'GRealTimeCheck'

```

# 使用范例[详见demo]

```
- (void)setUp {
[GRealTimeUtil shareInstance].noNetToNetNeedUpdateTime = YES; //是否网络变化校准

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
```


