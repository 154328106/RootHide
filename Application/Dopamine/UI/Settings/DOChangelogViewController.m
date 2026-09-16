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

    // 大卡片承载（对齐图二样式）
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithRed:0.22 green:0.52 blue:0.80 alpha:0.20];
    card.layer.cornerRadius = 20;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithRed:0.78 green:0.94 blue:1.0 alpha:0.42].CGColor;
    [self.view addSubview:card];

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:14],
        [card.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [card.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [card.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-24]
    ]];

    // 加粗标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Dopamine 3.0.9";
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor whiteColor];
    [card addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
        [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
        [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22]
    ]];

    // 编号条目
    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    textView.font = [UIFont systemFontOfSize:15];
    textView.text = [DOChangelogViewController changelogText];
    [card addSubview:textView];

    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12],
        [textView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [textView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [textView.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];
}

+ (NSString *)changelogText
{
    return @"1. 修复在 iOS 18.4+ 上移除越狱时，越狱应用未从主屏幕移除的问题\n\n"
        @"2. 当设备已越狱时，从设置中移除“移除越狱”按钮，因其不够稳定；现在该按钮仅在 TrollStore 安装且未越狱时显示。非 TrollStore 安装唯一支持的卸载流程现在是重启并在启用“移除越狱”开关的情况下重新越狱\n\n"
        @"3. 修复应用设置中“隐藏越狱”说明不显示的问题 [2.5测试版回归]\n\n"
        @"4. 改进应用设置中“隐藏越狱”的说明，以减少对其功能的混淆，并强调用户应自行承担使用风险\n";
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
