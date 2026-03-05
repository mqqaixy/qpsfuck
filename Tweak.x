// Tweak.x
#import <UIKit/UIKit.h>

// 全局变量（测试用）
static BOOL spoofingEnabled = NO;
static double fakeLat = 39.9042;
static double fakeLng = 116.4074;

// 启动时弹窗（证明注入成功）
%hook UIApplication

- (void)_run {
    %orig;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"注入成功"
                                                                   message:@"插件已加载！\n现在任意界面两指长按试试"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

%end

// 两指长按弹出经纬度输入框
%hook UIWindow

- (void)becomeKeyWindow {
    %orig;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleFakeLocationLongPress:)];
    longPress.minimumPressDuration = 1.5;
    longPress.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:longPress];
}

%new
- (void)handleFakeLocationLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"虚拟定位"
                                                                       message:@"输入纬度,经度（例如 39.9042,116.4074）"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"纬度,经度";
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *input = alert.textFields.firstObject.text;
            NSArray *parts = [input componentsSeparatedByString:@","];
            if (parts.count == 2) {
                fakeLat = [parts[0] doubleValue];
                fakeLng = [parts[1] doubleValue];
                spoofingEnabled = YES;
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"设置成功"
                                                                                message:@"位置已修改为输入坐标"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                [success addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [topVC presentViewController:success animated:YES completion:nil];
            }
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [topVC presentViewController:alert animated:YES completion:nil];
    }
}

%end

// 核心 hook - 伪造位置
%hook CLLocation

- (CLLocationCoordinate2D)coordinate {
    if (spoofingEnabled) {
        return CLLocationCoordinate2DMake(fakeLat, fakeLng);
    }
    return %orig;
}

- (double)latitude {
    return spoofingEnabled ? fakeLat : %orig;
}

- (double)longitude {
    return spoofingEnabled ? fakeLng : %orig;
}

%end
