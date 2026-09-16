//
//  DOPSListController.m
//  Dopamine
//
//  Created by tomt000 on 26/01/2024.
//

#import "DOPSListController.h"
#import "DOThemeManager.h"
#import "DOButtonCell.h"
#import "DOCreditsCell.h"

@interface DOPSListController ()

@end

@implementation DOPSListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_table setSeparatorColor:[UIColor clearColor]];
    [_table setBackgroundColor:[UIColor clearColor]];
    [DOPSListController setupViewControllerStyle:self];
}

+ (void)setupViewControllerStyle:(UIViewController*)vc
{
    DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
    
    vc.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    // 原来用 theme.windowColor（半透明深灰）显得暗；改成首页那种亮蓝半透明，通透一些
    vc.view.backgroundColor = [UIColor colorWithRed:0.16 green:0.42 blue:0.66 alpha:0.52];
    vc.view.layer.cornerRadius = 16;
    vc.view.layer.masksToBounds = YES;
    vc.view.layer.cornerCurve = kCACornerCurveContinuous;
    vc.view.layer.borderWidth = 1.5;   // 整个子页面加外边框，边缘看得清
    vc.view.layer.borderColor = [UIColor colorWithRed:0.80 green:0.95 blue:1.0 alpha:0.48].CGColor;
    
    if (@available(iOS 19.0, *)) {
        // Apple broke the method below by reimplementing some Preferences.framework classes in SwiftUI 🤮
        // Now onTintColor is only implemented when the cell is initialized but gets reset to the stock color when the cell is reused
        // I tried hard to fix it but failed in the end, so we will need to just use the stock tint color on iOS 26.0+
    }
    else {
        [UISwitch appearanceWhenContainedInInstancesOfClasses:@[[vc class]]].onTintColor = [UIColor colorWithRed: 71.0/255.0 green: 169.0/255.0 blue: 135.0/255.0 alpha: 1.0];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    // 开关行等系统 cell 直接浮在亮背景上看不清；给它们垫一层半透明卡片承载。
    // DOButtonCell / DOCreditsCell 自己已经画了卡，跳过。
    if (![cell isKindOfClass:[DOButtonCell class]] && ![cell isKindOfClass:[DOCreditsCell class]]) {
        // 卡片内缩到和「移除越狱」按钮同宽（左右各 20），颜色也用同款亮蓝，跟整体合群
        UIView *container = [[UIView alloc] initWithFrame:cell.bounds];
        container.backgroundColor = [UIColor clearColor];
        UIView *card = [[UIView alloc] initWithFrame:CGRectInset(cell.bounds, 20, 3)];
        card.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        card.backgroundColor = [UIColor colorWithRed:0.22 green:0.52 blue:0.80 alpha:0.20];
        card.layer.cornerRadius = 12;
        card.layer.cornerCurve = kCACornerCurveContinuous;
        card.layer.borderWidth = 1;
        card.layer.borderColor = [UIColor colorWithRed:0.78 green:0.94 blue:1.0 alpha:0.42].CGColor;
        [container addSubview:card];
        cell.backgroundView = container;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _table.frame = CGRectMake(12, 5, self.view.bounds.size.width - 24, self.view.bounds.size.height - 10);
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
