//
//  DOCreditsCell.m
//  Dopamine
//
//  Created by tomt000 on 26/01/2024.
//

#import "DOCreditsCell.h"
#import "DOGlobalAppearance.h"

#define CREDITS_CELL_HEIGHT 35

@interface DOCreditsCellItem : UICollectionViewCell
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSURL *url;
@end

@implementation DOCreditsCellItem

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.label = [[UILabel alloc] init];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.label.textColor = [UIColor whiteColor];
        self.label.alpha = 0.65;
        self.label.textAlignment = NSTextAlignmentLeft;

        [self.contentView addSubview:self.label];
        [NSLayoutConstraint activateConstraints:@[
            [self.label.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor constant:-17 * ([DOGlobalAppearance isRTL] ? -1 : 1)],
            [self.label.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        ]];

        UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.right"];
        chevronImage = [chevronImage imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightRegular]];
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevronImage];
        chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        chevronView.tintColor = [UIColor colorWithWhite:1 alpha:self.label.alpha];
        [self.contentView addSubview:chevronView];
        [NSLayoutConstraint activateConstraints:@[
            [chevronView.trailingAnchor constraintEqualToAnchor:self.label.trailingAnchor constant:17],
            [chevronView.centerYAnchor constraintEqualToAnchor:self.label.centerYAnchor],
        ]];
        
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.alpha = 0.5;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 1.0;
    }];
    if (self.url)
        [[UIApplication sharedApplication] openURL:self.url options:@{} completionHandler:nil];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)setName:(NSString*)name url:(NSURL*)url
{
    self.label.text = name;
    self.url = url;
}

@end


@interface DOCreditsCell ()
@property (nonatomic, strong) NSArray<NSDictionary*> *names;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *sectionTitleLabel;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIVisualEffectView *cardBlurView;
@end

@implementation DOCreditsCell

- (id)initWithSpecifier:(PSSpecifier*)specifier
{
    if (self = [super init])
    {
        self.names = [specifier propertyForKey:@"names"];

        self.cardView = [[UIView alloc] init];
        self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cardView.layer.cornerRadius = 18;
        self.cardView.layer.cornerCurve = kCACornerCurveContinuous;
        self.cardView.layer.masksToBounds = YES;
        self.cardView.layer.borderWidth = 1;
        self.cardView.layer.borderColor = [UIColor colorWithRed:0.56 green:0.87 blue:1.0 alpha:0.19].CGColor;
        [self.contentView addSubview:self.cardView];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        self.cardBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.cardBlurView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cardBlurView.userInteractionEnabled = NO;
        self.cardBlurView.alpha = 0.58;
        self.cardBlurView.contentView.backgroundColor = [UIColor colorWithRed:0.16 green:0.55 blue:0.76 alpha:0.035];
        [self.cardView addSubview:self.cardBlurView];

        self.sectionTitleLabel = [[UILabel alloc] init];
        self.sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.sectionTitleLabel.text = [specifier propertyForKey:@"sectionTitle"];
        self.sectionTitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        self.sectionTitleLabel.textColor = [UIColor colorWithRed:0.72 green:0.88 blue:0.98 alpha:0.80];
        self.sectionTitleLabel.textAlignment = NSTextAlignmentLeft;
        [self.cardView addSubview:self.sectionTitleLabel];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);

        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;

        [self.collectionView registerClass:[DOCreditsCellItem class] forCellWithReuseIdentifier:@"item"];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        
        [self.cardView addSubview:self.collectionView];

        [NSLayoutConstraint activateConstraints:@[
            [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:32],
            [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-32],
            [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],

            [self.cardBlurView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
            [self.cardBlurView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
            [self.cardBlurView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
            [self.cardBlurView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],

            [self.sectionTitleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
            [self.sectionTitleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
            [self.sectionTitleLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:14],
            [self.sectionTitleLabel.heightAnchor constraintEqualToConstant:18],

            [self.collectionView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:12],
            [self.collectionView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-12],
            [self.collectionView.topAnchor constraintEqualToAnchor:self.sectionTitleLabel.bottomAnchor constant:8],
            [self.collectionView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-12],
        ]];
        
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.names.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DOCreditsCellItem *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"item" forIndexPath:indexPath];
    NSDictionary *name = self.names[indexPath.row];
    [cell setName:name[@"name"] url:[NSURL URLWithString:name[@"link"]]];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width/2, CREDITS_CELL_HEIGHT);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
    return 58 + CREDITS_CELL_HEIGHT * ceil(self.names.count/2.0);
}



@end
