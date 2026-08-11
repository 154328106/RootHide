//
//  DOActionMenuView.m
//  Dopamine
//
//  Created by tomt000 on 04/01/2024.
//

#import "DOActionMenuView.h"
#import "DOActionMenuButton.h"
#import "DOGlobalAppearance.h"
#import "DOThemeManager.h"

@implementation DOActionMenuView

- (instancetype)initWithActions:(NSArray<UIAction*> *)actions delegate:(id<DOActionMenuDelegate>)delegate
{
    if (self = [super init])
    {
        [self setDelegate:delegate];
        [self setActions:actions];
        self.backgroundColor = [UIColor colorWithRed:0.58 green:0.82 blue:1.0 alpha:0.10];
        self.layer.cornerRadius = 28;
        self.layer.masksToBounds = YES;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 1.15;
        self.layer.borderColor = [UIColor colorWithRed:0.80 green:0.94 blue:1.0 alpha:0.48].CGColor;

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.userInteractionEnabled = NO;
        blurView.translatesAutoresizingMaskIntoConstraints = NO;
        blurView.contentView.backgroundColor = [UIColor colorWithRed:0.64 green:0.86 blue:1.0 alpha:0.08];
        [self insertSubview:blurView atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    }
    return self;
}

- (void)setActions:(NSArray *)actions
{
    _actions = actions;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshStack];
    });
}

-(void)refreshStack
{
    [self.buttonsView removeFromSuperview];
    self.buttonsView = [[UIStackView alloc] init];
    self.buttonsView.axis = UILayoutConstraintAxisVertical;
    self.buttonsView.spacing = 0;
    self.buttonsView.translatesAutoresizingMaskIntoConstraints = NO;

    int button_height = [DOGlobalAppearance isHomeButtonDevice] ? UI_ACTION_HEIGHT_HOME_BTN : UI_ACTION_HEIGHT;
    if ([DOGlobalAppearance isSmallDevice])
        button_height = UI_ACTION_HEIGHT_TINY;

    [self.actions enumerateObjectsUsingBlock:^(UIAction *action, NSUInteger idx, BOOL *stop) {
        DOActionMenuButton *button = [DOActionMenuButton buttonWithAction:action chevron:[self.delegate actionMenuShowsChevronForAction:action]];
        button.enabled = [self.delegate actionMenuActionIsEnabled:action];
        [button setBottomSeparator:idx != self.actions.count - 1];
        [self.buttonsView addArrangedSubview:button];
        [NSLayoutConstraint activateConstraints:@[
            [button.heightAnchor constraintEqualToConstant:button_height],
            [button.widthAnchor constraintEqualToAnchor:self.buttonsView.widthAnchor]
        ]];
    }];

    [self addSubview:self.buttonsView];

    int inner_padding = [DOGlobalAppearance isSmallDevice] ? UI_INNER_PADDING_TINY : UI_INNER_PADDING;

    [NSLayoutConstraint activateConstraints:@[
        [self.buttonsView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:inner_padding],
        [self.buttonsView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-inner_padding],
        [self.buttonsView.topAnchor constraintEqualToAnchor:self.topAnchor constant:UI_INNER_TOP_PADDING],
        [self.buttonsView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-UI_INNER_TOP_PADDING],
    ]];

}

- (void)hide
{
    [self setUserInteractionEnabled:NO];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -75);
    transform = CGAffineTransformScale(transform, 0.6, 0.6);
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:2.0  options: UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setAlpha:0.0];
        [self setTransform:transform];
    } completion:nil];
}

@end
