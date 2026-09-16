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

    if (chevron)
    {
        UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.right"];
        chevronImage = [chevronImage imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular]];
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevronImage];
        chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        chevronView.tintColor = [UIColor colorWithRed:0.46 green:1.0 blue:0.88 alpha:0.72];
        [button addSubview:chevronView];
        [NSLayoutConstraint activateConstraints:@[
            [chevronView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-22],
            [chevronView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        ]];
    }

    button.feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [button addTarget:button action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

-(void)addInnerCard
{
    // 菜单项小框：横向内缩 12（比大框短一圈），上下内缩 4；提亮的通透蓝 + 淡青描边。
    UIView *cardView = [[UIView alloc] init];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    cardView.userInteractionEnabled = NO;
    cardView.backgroundColor = [UIColor colorWithRed:0.30 green:0.62 blue:0.92 alpha:0.28];
    cardView.layer.cornerRadius = 16;
    cardView.layer.cornerCurve = kCACornerCurveContinuous;
    cardView.layer.borderWidth = 1.0;
    cardView.layer.borderColor = [UIColor colorWithRed:0.78 green:0.95 blue:1.0 alpha:0.45].CGColor;
    [self insertSubview:cardView atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [cardView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [cardView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [cardView.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
        [cardView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
    ]];
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
