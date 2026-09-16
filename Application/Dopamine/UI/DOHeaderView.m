//
//  DOHeaderView.m
//  Dopamine
//
//  Created by tomt000 on 04/01/2024.
//

#import "DOHeaderView.h"
#import "DOThemeManager.h"

@interface DOHeaderView ()

@property (nonatomic) UIImageView *logoView;
@property (nonatomic, readwrite) UILabel *uptimeLabel;

@end

@implementation DOHeaderView

-(id)initWithImage:(UIImage *)image subtitles:(NSArray<NSAttributedString *> *)subtitles {
    if (self = [super init]) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 2;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.alignment = UIStackViewAlignmentCenter;

        // 顶部标题小框：比 header 区窄一圈（左右各缩 26 = 看起来小一些），文字在框内留白。
        // 与菜单项小框同一套玻璃风格，形成上下呼应。
        UIView *cardBg = [[UIView alloc] init];
        cardBg.translatesAutoresizingMaskIntoConstraints = NO;
        cardBg.userInteractionEnabled = NO;
        cardBg.backgroundColor = [UIColor colorWithRed:0.10 green:0.44 blue:0.70 alpha:0.18];
        cardBg.layer.cornerRadius = 18;
        cardBg.layer.cornerCurve = kCACornerCurveContinuous;
        cardBg.layer.borderWidth = 1.0;
        cardBg.layer.borderColor = [UIColor colorWithRed:0.62 green:0.90 blue:1.0 alpha:0.22].CGColor;
        [self addSubview:cardBg];

        [self addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            // 框：左右内缩 26（窄=小一些），上下贴 header 边
            [cardBg.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:26],
            [cardBg.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-26],
            [cardBg.topAnchor constraintEqualToAnchor:self.topAnchor],
            [cardBg.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            // 文字：在框内再留白（左右 40 / 上下 14）
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:40],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-40],
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:14],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-14],
        ]];

        // Personal build wordmark. Text scales more cleanly than modifying the
        // upstream logo asset and remains readable over every glass background.
        UILabel *wordmark = [[UILabel alloc] init];
        wordmark.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *wordmarkText = @"Dopamine RH";
        UIFont *baseFont = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        UIFontDescriptor *roundedDescriptor = [baseFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
        UIFont *wordmarkFont = roundedDescriptor ? [UIFont fontWithDescriptor:roundedDescriptor size:30] : baseFont;
        wordmark.attributedText = [[NSAttributedString alloc] initWithString:wordmarkText attributes:@{
            NSFontAttributeName: wordmarkFont,
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.86 green:0.96 blue:1.0 alpha:1.0],
            NSKernAttributeName: @0.15,
        }];
        wordmark.textAlignment = NSTextAlignmentCenter;
        wordmark.adjustsFontSizeToFitWidth = YES;
        wordmark.minimumScaleFactor = 0.82;
        wordmark.numberOfLines = 1;
        wordmark.layer.shadowColor = [UIColor colorWithRed:0.20 green:0.65 blue:1.0 alpha:1.0].CGColor;
        wordmark.layer.shadowOffset = CGSizeZero;
        wordmark.layer.shadowRadius = 8;
        wordmark.layer.shadowOpacity = 0.30;
        [stackView addArrangedSubview:wordmark];

        [NSLayoutConstraint activateConstraints:@[
            [wordmark.heightAnchor constraintEqualToConstant:38],
            [wordmark.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
        ]];

        //3 - Add our subtitles to our stack
        [subtitles enumerateObjectsUsingBlock:^(NSAttributedString *formatedText, NSUInteger idx, BOOL *stop) {
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = formatedText;
            label.textAlignment = NSTextAlignmentCenter;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [stackView addArrangedSubview:label];
        }];

        self.uptimeLabel = [[UILabel alloc] init];
        self.uptimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.uptimeLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
        self.uptimeLabel.textAlignment = NSTextAlignmentCenter;
        self.uptimeLabel.textColor = [UIColor colorWithRed:0.62 green:0.88 blue:1.0 alpha:0.86];
        self.uptimeLabel.text = @"";
        self.uptimeLabel.hidden = YES;
        [stackView addArrangedSubview:self.uptimeLabel];

        self.translatesAutoresizingMaskIntoConstraints = NO;

        DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
        if (theme.titleShadow)
        {
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowRadius = 30;
            self.layer.shadowOpacity = 0.3;
        }

    }
    return self;
}

@end
