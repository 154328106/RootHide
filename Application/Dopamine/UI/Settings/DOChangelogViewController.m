//
//  DOChangelogViewController.m
//  Dopamine
//

#import "DOChangelogViewController.h"
#import "DOPSListController.h"
#import "DOPSListItemsController.h"

@implementation DOChangelogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [DOPSListController setupViewControllerStyle:self];

    UIView *header = [DOPSListItemsController makeHeader:@"更新日志" withTarget:self];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:5],
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [header.heightAnchor constraintEqualToConstant:70]
    ]];

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:15];
    textView.text = [DOChangelogViewController changelogText];
    [self.view addSubview:textView];

    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:22],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-22],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20]
    ]];
}

+ (NSString *)changelogText
{
    return @"Dopamine 3.0.9 更新日志

"
        @"1. 修复在 iOS 18.4+ 上移除越狱时，越狱应用未从主屏幕移除的问题

"
        @"2. 当设备已越狱时，从设置中移除“移除越狱”按钮，因其不够稳定；现在该按钮仅在 TrollStore 安装且未越狱时显示。非 TrollStore 安装唯一支持的卸载流程现在是重启并在启用“移除越狱”开关的情况下重新越狱

"
        @"3. 修复应用设置中“隐藏越狱”说明不显示的问题 [2.5测试版回归]

"
        @"4. 改进应用设置中“隐藏越狱”的说明，以减少对其功能的混淆，并强调用户应自行承担使用风险
";
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
