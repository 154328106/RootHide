//
//  DOActionButton.h
//  Dopamine
//
//  Created by tomt000 on 07/01/2024.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DOActionMenuButton : UIButton

@property (nonatomic) BOOL bottomSeparator;

+(DOActionMenuButton*)buttonWithAction:(UIAction *)action chevron:(BOOL)chevron;

// 给菜单项套一层内缩小框；越狱按钮/更新按钮不调用它，避免多套一层
-(void)addInnerCard;

@end

NS_ASSUME_NONNULL_END
