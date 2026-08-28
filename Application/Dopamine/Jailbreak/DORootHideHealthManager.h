//
//  DORootHideHealthManager.h
//  Dopamine
//
//  Read-only RootHide health checks with narrowly scoped repair actions.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DORootHideHealthState) {
    DORootHideHealthStateUnknown = 0,
    DORootHideHealthStateHealthy,
    DORootHideHealthStateWarning,
    DORootHideHealthStateRepairable,
    DORootHideHealthStateConflict,
    DORootHideHealthStateDisabled,
};

extern NSString *const DORootHideHealthIdentifierBootstrap;
extern NSString *const DORootHideHealthIdentifierJailbreakApps;
extern NSString *const DORootHideHealthIdentifierSileo;
extern NSString *const DORootHideHealthIdentifierZebra;
extern NSString *const DORootHideHealthIdentifierInjection;

@interface DORootHideHealthItem : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *detail;
@property (nonatomic, readonly) DORootHideHealthState state;
@property (nonatomic, readonly) BOOL canRepair;

- (NSString *)localizedStateTitle;

@end

@interface DORootHideHealthManager : NSObject

+ (instancetype)sharedManager;

// These methods may inspect LaunchServices and the RootHide filesystem and
// should therefore be called from a background queue.
- (NSArray<DORootHideHealthItem *> *)scanHealth;
- (nullable NSError *)repairItemWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
