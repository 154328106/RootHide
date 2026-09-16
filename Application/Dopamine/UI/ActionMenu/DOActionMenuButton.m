//
//  DOActionMenuButton.m
//  Dopamine
//
//  Created by tomt000 on 07/01/2024.
//

#import "DOActionMenuButton.h"
#import "DOGlobalAppearance.h"

@interface DOActionMenuButton () {
    UIView *_separator;
}

@property (nonatomic) UIImpactFeedbackGenerator *feedbackGenerator;

@end

@implementation DOActionMenuButton 

+(DOActionMenuButton*)buttonWithAction:(UIAction *)action chevron:(BOOL)chevron
{
    DOActionMenuButton *button = [DOActionMenuButton buttonWithConfiguration:[DOGlobalAppearance defaultButtonConfiguration] primaryAction:action];
    [button.titleLabel setAdjustsFontSizeToFitWidth:YES];
    // 标题居中（原来是靠左）；图标跟标题一起居中
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];

    // 每个菜单项各自套一个小框（大框里的小框）：内缩 4pt，相邻两项之间自然留 8pt 缝，
    // 比外层大框亮一点点 + 一圈淡青描边，形成「大框套小框」的层次感。
    UIView *cardView = [[UIView alloc] init];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    cardView.userInteractionEnabled = NO;
    cardView.backgroundColor = [UIColor colorWithRed:0.10 green:0.44 blue:0.70 alpha:0.22];
    cardView.layer.cornerRadius = 16;
    cardView.layer.cornerCurve = kCACornerCurveContinuous;
    cardView.layer.borderWidth = 1.0;
    cardView.layer.borderColor = [UIColor colorWithRed:0.62 green:0.90 blue:1.0 alpha:0.24].CGColor;
    [button insertSubview:cardView atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [cardView.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [cardView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [cardView.topAnchor constraintEqualToAnchor:button.topAnchor constant:4],
        [cardView.bottomAnchor constraintEqualToAnchor:button.bottomAnchor constant:-4],
    ]];

    if (chevron)
    {
        UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.right"];
        chevronImage = [chevronImage imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular]];
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevronImage];
        chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        chevronView.tintColor = [UIColor colorWithRed:0.46 green:1.0 blue:0.88 alpha:0.72];
        [button addSubview:chevronView];
        [NSLayoutConstraint activateConstraints:@[
            [chevronView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-10],
            [chevronView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        ]];
    }

    button.feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [button addTarget:button action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

-(void)buttonPressed
{
    [self.feedbackGenerator impactOccurred];
}

-(void)setBottomSeparator:(BOOL)bottomSeparator
{
    _bottomSeparator = bottomSeparator;
    [_separator removeFromSuperview];
    _separator = nil;

    if (bottomSeparator)
    {
        _separator = [[UIView alloc] init];
        _separator.backgroundColor = [UIColor colorWithRed:0.55 green:0.84 blue:1.0 alpha:0.14];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_separator];
        [NSLayoutConstraint activateConstraints:@[
            [_separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_separator.heightAnchor constraintEqualToConstant:0.5],
        ]];
    }
}

@end
