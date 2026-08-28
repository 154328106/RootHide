//
//  DORootHideHealthManager.m
//  Dopamine
//

#import "DORootHideHealthManager.h"
#import "DOEnvironmentManager.h"
#import "DOUIManager.h"

#import <CoreServices/LSApplicationProxy.h>
#import <libjailbreak/info.h>
#import <libjailbreak/util.h>

NSString *const DORootHideHealthIdentifierBootstrap = @"bootstrap";
NSString *const DORootHideHealthIdentifierJailbreakApps = @"jailbreak-apps";
NSString *const DORootHideHealthIdentifierSileo = @"org.coolstar.SileoStore";
NSString *const DORootHideHealthIdentifierZebra = @"xyz.willy.Zebra";
NSString *const DORootHideHealthIdentifierInjection = @"injection";

static NSString *const DORootHideHealthErrorDomain = @"DORootHideHealthErrorDomain";

@interface DORootHideHealthItem ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *detail;
@property (nonatomic, readwrite) DORootHideHealthState state;
@property (nonatomic, readwrite) BOOL canRepair;
@end

@implementation DORootHideHealthItem

- (NSString *)localizedStateTitle
{
    switch (self.state) {
        case DORootHideHealthStateHealthy:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Healthy")];
        case DORootHideHealthStateWarning:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Warning")];
        case DORootHideHealthStateRepairable:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Repairable")];
        case DORootHideHealthStateConflict:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Conflict")];
        case DORootHideHealthStateDisabled:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Disabled")];
        case DORootHideHealthStateUnknown:
        default:
            return [NSString stringWithFormat:@"● %@", DOLocalizedString(@"Health_Status_Unknown")];
    }
}

@end

@interface DORootHideHealthManager ()
@property (nonatomic, strong, readonly) NSFileManager *fileManager;
@end

@implementation DORootHideHealthManager

+ (instancetype)sharedManager
{
    static DORootHideHealthManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (DORootHideHealthItem *)itemWithIdentifier:(NSString *)identifier
                                        title:(NSString *)title
                                       detail:(NSString *)detail
                                        state:(DORootHideHealthState)state
                                    canRepair:(BOOL)canRepair
{
    DORootHideHealthItem *item = [[DORootHideHealthItem alloc] init];
    item.identifier = identifier;
    item.title = title;
    item.detail = detail;
    item.state = state;
    item.canRepair = canRepair;
    return item;
}

- (NSError *)errorWithDescription:(NSString *)description
{
    return [NSError errorWithDomain:DORootHideHealthErrorDomain
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey : description ?: DOLocalizedString(@"Health_Repair_Failed")}];
}

- (NSString *)canonicalPath:(NSString *)path
{
    if (path.length == 0) return @"";
    return [[path stringByResolvingSymlinksInPath] stringByStandardizingPath];
}

- (BOOL)path:(NSString *)left equalsPath:(NSString *)right
{
    if (left.length == 0 || right.length == 0) return NO;
    return [[self canonicalPath:left] isEqualToString:[self canonicalPath:right]];
}

- (BOOL)isRootHideManagedApplicationPath:(NSString *)path
{
    if (path.length == 0) return NO;
    NSString *standardPath = [path stringByStandardizingPath];
    NSString *pattern = @"^(?:/private)?/var/containers/Bundle/Application/\\.jbroot-[0-9A-Fa-f]{16}/Applications/[^/]+\\.app(?:/|$)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    return [expression firstMatchInString:standardPath
                                  options:0
                                    range:NSMakeRange(0, standardPath.length)] != nil;
}

- (uint64_t)currentJailbreakBrand
{
    uint64_t brand = jbinfo(jbrand);
    if (brand != 0) return brand;

    // On an app relaunch DOEnvironmentManager restores rootPath from
    // jailbreakd, but the in-process gSystemInfo jbrand field may still be
    // zero. Derive it only from the strictly formatted active RootHide root.
    NSString *rootPath = [JBROOT_PATH(@"/") stringByStandardizingPath];
    NSString *pattern = @"(?:^|/)\\.jbroot-([0-9A-Fa-f]{16})(?:/|$)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [expression firstMatchInString:rootPath options:0 range:NSMakeRange(0, rootPath.length)];
    if (!match || match.numberOfRanges < 2) return 0;

    NSString *hexBrand = [rootPath substringWithRange:[match rangeAtIndex:1]];
    unsigned long long parsedBrand = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexBrand];
    if (![scanner scanHexLongLong:&parsedBrand] || !scanner.isAtEnd) return 0;
    return (uint64_t)parsedBrand;
}

- (NSString *)registeredPathForBundleIdentifier:(NSString *)bundleIdentifier
{
    if (bundleIdentifier.length == 0) return nil;
    LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier];
    if (!proxy || !proxy.installed || proxy.bundleURL.path.length == 0) return nil;
    return proxy.bundleURL.path;
}

- (BOOL)waitForBundleIdentifier:(NSString *)bundleIdentifier registeredAtPath:(NSString *)expectedPath
{
    for (NSUInteger attempt = 0; attempt < 20; attempt++) {
        NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
        BOOL matches = expectedPath.length
            ? [self path:registeredPath equalsPath:expectedPath]
            : (registeredPath.length == 0);
        if (matches) return YES;
        [NSThread sleepForTimeInterval:0.05];
    }
    return NO;
}

- (NSDictionary<NSString *, NSString *> *)userApplicationPathsForBundleIdentifiers:(NSSet<NSString *> *)bundleIdentifiers
{
    if (bundleIdentifiers.count == 0) return @{};

    NSMutableDictionary<NSString *, NSString *> *matches = [NSMutableDictionary new];
    NSString *userApplicationsPath = @"/var/containers/Bundle/Application";
    NSArray<NSString *> *containers = [self.fileManager contentsOfDirectoryAtPath:userApplicationsPath error:nil] ?: @[];

    for (NSString *containerName in containers) {
        // RootHide itself lives below a hidden .jbroot-* directory here. It is
        // not a real user app container and must never be treated as one.
        if ([containerName hasPrefix:@"."]) continue;

        NSString *containerPath = [userApplicationsPath stringByAppendingPathComponent:containerName];
        NSArray<NSString *> *contents = [self.fileManager contentsOfDirectoryAtPath:containerPath error:nil] ?: @[];
        for (NSString *candidate in contents) {
            if (![candidate.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
            NSString *appPath = [containerPath stringByAppendingPathComponent:candidate];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"]];
            NSString *bundleIdentifier = info[@"CFBundleIdentifier"];
            if ([bundleIdentifiers containsObject:bundleIdentifier] && !matches[bundleIdentifier]) {
                matches[bundleIdentifier] = appPath;
            }
        }
    }
    return matches;
}

- (NSArray<NSDictionary *> *)jailbreakApplicationRecords
{
    NSString *applicationsPath = JBROOT_PATH(@"/Applications");
    NSArray<NSString *> *contents = [self.fileManager contentsOfDirectoryAtPath:applicationsPath error:nil] ?: @[];
    NSMutableArray<NSDictionary *> *records = [NSMutableArray new];

    for (NSString *candidate in contents) {
        if (![candidate.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
        NSString *appPath = [applicationsPath stringByAppendingPathComponent:candidate];
        BOOL isDirectory = NO;
        if (![self.fileManager fileExistsAtPath:appPath isDirectory:&isDirectory] || !isDirectory) continue;

        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"]];
        NSString *bundleIdentifier = info[@"CFBundleIdentifier"];
        [records addObject:@{
            @"Path" : appPath,
            @"Name" : candidate.stringByDeletingPathExtension,
            @"BundleIdentifier" : bundleIdentifier ?: @"",
        }];
    }
    return records;
}

- (NSDictionary *)packageManagerConfigurationForKey:(NSString *)key
{
    for (NSDictionary *configuration in [[DOUIManager sharedInstance] availablePackageManagers]) {
        if ([configuration[@"Key"] isEqualToString:key]) return configuration;
    }
    return nil;
}

- (NSDictionary *)installedPackageInfoForIdentifier:(NSString *)identifier
{
    if (identifier.length == 0) return nil;
    NSString *status = [NSString stringWithContentsOfFile:JBROOT_PATH(@"/var/lib/dpkg/status")
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    status = [status stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    NSString *packageLine = [NSString stringWithFormat:@"Package: %@", identifier];
    for (NSString *paragraph in [status componentsSeparatedByString:@"\n\n"]) {
        NSArray<NSString *> *lines = [paragraph componentsSeparatedByString:@"\n"];
        if (![lines containsObject:packageLine]) continue;

        NSMutableDictionary *result = [NSMutableDictionary new];
        for (NSString *line in lines) {
            NSRange separator = [line rangeOfString:@": "];
            if (separator.location == NSNotFound) continue;
            NSString *field = [line substringToIndex:separator.location];
            NSString *value = [line substringFromIndex:NSMaxRange(separator)];
            if (field.length && value.length) result[field] = value;
        }
        return result;
    }
    return nil;
}

- (BOOL)isPackageInstalled:(NSDictionary *)packageInfo
{
    return [packageInfo[@"Status"] isEqualToString:@"install ok installed"];
}

- (DORootHideHealthItem *)bootstrapHealthItem
{
    NSMutableArray<NSString *> *missing = [NSMutableArray new];
    NSDictionary<NSString *, NSNumber *> *requiredPaths = @{
        @".installed_dopamine" : @NO,
        @"basebin/.version" : @NO,
        @"basebin/jbctl" : @YES,
        @"usr/bin/dpkg" : @YES,
        @"usr/bin/uicache" : @YES,
    };

    if (![DOEnvironmentManager sharedManager].isBootstrapped) {
        [missing addObject:@"JBROOT"];
    }
    [requiredPaths enumerateKeysAndObjectsUsingBlock:^(NSString *relativePath, NSNumber *mustBeExecutable, BOOL *stop) {
        NSString *path = [JBROOT_PATH(@"/") stringByAppendingPathComponent:relativePath];
        BOOL present = mustBeExecutable.boolValue ? [self.fileManager isExecutableFileAtPath:path] : [self.fileManager fileExistsAtPath:path];
        if (!present) [missing addObject:relativePath.lastPathComponent];
    }];

    if (missing.count) {
        NSString *detail = [NSString stringWithFormat:DOLocalizedString(@"Health_Bootstrap_Warning_Detail"), [missing componentsJoinedByString:@", "]];
        return [self itemWithIdentifier:DORootHideHealthIdentifierBootstrap
                                  title:DOLocalizedString(@"Health_Bootstrap")
                                 detail:detail
                                  state:DORootHideHealthStateWarning
                              canRepair:NO];
    }
    return [self itemWithIdentifier:DORootHideHealthIdentifierBootstrap
                              title:DOLocalizedString(@"Health_Bootstrap")
                             detail:DOLocalizedString(@"Health_Bootstrap_Healthy_Detail")
                              state:DORootHideHealthStateHealthy
                          canRepair:NO];
}

- (DORootHideHealthItem *)jailbreakApplicationsHealthItem
{
    NSArray<NSDictionary *> *records = [self jailbreakApplicationRecords];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *pathsByIdentifier = [NSMutableDictionary new];
    NSUInteger invalidCount = 0;

    for (NSDictionary *record in records) {
        NSString *bundleIdentifier = record[@"BundleIdentifier"];
        if (bundleIdentifier.length == 0) {
            invalidCount++;
            continue;
        }
        if (!pathsByIdentifier[bundleIdentifier]) pathsByIdentifier[bundleIdentifier] = [NSMutableArray new];
        [pathsByIdentifier[bundleIdentifier] addObject:record[@"Path"]];
    }

    NSMutableSet<NSString *> *identifiers = [NSMutableSet setWithArray:pathsByIdentifier.allKeys];
    NSDictionary<NSString *, NSString *> *userConflicts = [self userApplicationPathsForBundleIdentifiers:identifiers];
    __block NSUInteger duplicateCount = 0;
    __block NSUInteger conflictCount = userConflicts.count;
    __block NSUInteger missingCount = 0;
    __block NSUInteger staleCount = 0;

    [pathsByIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *bundleIdentifier, NSMutableArray<NSString *> *paths, BOOL *stop) {
        if (paths.count > 1) {
            duplicateCount++;
            return;
        }
        NSString *expectedPath = paths.firstObject;
        NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
        if (registeredPath.length == 0) {
            missingCount++;
        }
        else if (![self path:registeredPath equalsPath:expectedPath]) {
            if ([self isRootHideManagedApplicationPath:registeredPath]) staleCount++;
            else if (!userConflicts[bundleIdentifier]) conflictCount++;
        }
    }];

    if (duplicateCount || conflictCount) {
        NSString *detail = [NSString stringWithFormat:DOLocalizedString(@"Health_Apps_Conflict_Detail"),
                            (unsigned long)duplicateCount, (unsigned long)conflictCount];
        return [self itemWithIdentifier:DORootHideHealthIdentifierJailbreakApps
                                  title:DOLocalizedString(@"Health_Jailbreak_Apps")
                                 detail:detail
                                  state:DORootHideHealthStateConflict
                              canRepair:NO];
    }
    if (invalidCount) {
        NSString *detail = [NSString stringWithFormat:DOLocalizedString(@"Health_Apps_Invalid_Detail"), (unsigned long)invalidCount];
        return [self itemWithIdentifier:DORootHideHealthIdentifierJailbreakApps
                                  title:DOLocalizedString(@"Health_Jailbreak_Apps")
                                 detail:detail
                                  state:DORootHideHealthStateWarning
                              canRepair:NO];
    }
    if (missingCount || staleCount) {
        NSString *detail = [NSString stringWithFormat:DOLocalizedString(@"Health_Apps_Repairable_Detail"),
                            (unsigned long)missingCount, (unsigned long)staleCount];
        return [self itemWithIdentifier:DORootHideHealthIdentifierJailbreakApps
                                  title:DOLocalizedString(@"Health_Jailbreak_Apps")
                                 detail:detail
                                  state:DORootHideHealthStateRepairable
                              canRepair:YES];
    }

    NSString *detail = records.count
        ? [NSString stringWithFormat:DOLocalizedString(@"Health_Apps_Healthy_Detail"), (unsigned long)records.count]
        : DOLocalizedString(@"Health_Apps_None_Detail");
    return [self itemWithIdentifier:DORootHideHealthIdentifierJailbreakApps
                              title:DOLocalizedString(@"Health_Jailbreak_Apps")
                             detail:detail
                              state:(records.count ? DORootHideHealthStateHealthy : DORootHideHealthStateWarning)
                          canRepair:NO];
}

- (DORootHideHealthItem *)packageManagerHealthItemForKey:(NSString *)key
{
    NSDictionary *configuration = [self packageManagerConfigurationForKey:key];
    NSString *displayName = configuration[@"Display Name"] ?: key;
    NSString *debianPackage = configuration[@"Debian Package"];
    NSString *applicationName = configuration[@"Application"];
    if (!configuration || debianPackage.length == 0 || applicationName.length == 0) {
        return [self itemWithIdentifier:key
                                  title:displayName
                                 detail:DOLocalizedString(@"Health_Package_Manager_Config_Missing_Detail")
                                  state:DORootHideHealthStateUnknown
                              canRepair:NO];
    }
    NSString *expectedPath = [JBROOT_PATH(@"/Applications") stringByAppendingPathComponent:applicationName ?: @""];
    NSDictionary *packageInfo = [self installedPackageInfoForIdentifier:debianPackage];
    BOOL packageInstalled = [self isPackageInstalled:packageInfo];
    BOOL appExists = applicationName.length && [self.fileManager fileExistsAtPath:expectedPath];
    NSDictionary *appInfo = appExists ? [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]] : nil;
    BOOL bundleValid = [appInfo[@"CFBundleIdentifier"] isEqualToString:key];
    NSString *registeredPath = [self registeredPathForBundleIdentifier:key];
    BOOL enabled = [[[DOUIManager sharedInstance] enabledPackageManagerKeys] containsObject:key];

    NSArray<NSDictionary *> *records = [self jailbreakApplicationRecords];
    NSUInteger matchingJailbreakApps = 0;
    BOOL unexpectedJailbreakOwner = NO;
    for (NSDictionary *record in records) {
        if ([record[@"BundleIdentifier"] isEqualToString:key]) {
            matchingJailbreakApps++;
            if (![self path:record[@"Path"] equalsPath:expectedPath]) unexpectedJailbreakOwner = YES;
        }
    }
    NSDictionary *userConflicts = [self userApplicationPathsForBundleIdentifiers:[NSSet setWithObject:key]];

    if (userConflicts[key] || matchingJailbreakApps > 1 || unexpectedJailbreakOwner ||
        (registeredPath.length && ![self path:registeredPath equalsPath:expectedPath] && ![self isRootHideManagedApplicationPath:registeredPath])) {
        return [self itemWithIdentifier:key
                                  title:displayName
                                 detail:DOLocalizedString(@"Health_Package_Manager_Conflict_Detail")
                                  state:DORootHideHealthStateConflict
                              canRepair:NO];
    }

    if (!enabled && !packageInstalled && !appExists) {
        if (registeredPath.length && [self isRootHideManagedApplicationPath:registeredPath]) {
            return [self itemWithIdentifier:key
                                      title:displayName
                                     detail:DOLocalizedString(@"Health_Package_Manager_Orphaned_Detail")
                                      state:DORootHideHealthStateRepairable
                                  canRepair:YES];
        }
        return [self itemWithIdentifier:key
                                  title:displayName
                                 detail:DOLocalizedString(@"Health_Package_Manager_Not_Installed_Detail")
                                  state:DORootHideHealthStateDisabled
                              canRepair:NO];
    }

    NSMutableArray<NSString *> *problems = [NSMutableArray new];
    if (!packageInstalled) [problems addObject:DOLocalizedString(@"Health_Problem_Package_Missing")];
    if (!appExists) [problems addObject:DOLocalizedString(@"Health_Problem_App_Missing")];
    else if (!bundleValid) [problems addObject:DOLocalizedString(@"Health_Problem_Bundle_Invalid")];
    if (bundleValid && registeredPath.length == 0) [problems addObject:DOLocalizedString(@"Health_Problem_Registration_Missing")];
    else if (bundleValid && ![self path:registeredPath equalsPath:expectedPath]) [problems addObject:DOLocalizedString(@"Health_Problem_Registration_Stale")];

    if (problems.count) {
        return [self itemWithIdentifier:key
                                  title:displayName
                                 detail:[problems componentsJoinedByString:@" · "]
                                  state:DORootHideHealthStateRepairable
                              canRepair:YES];
    }

    NSString *version = packageInfo[@"Version"] ?: @"?";
    return [self itemWithIdentifier:key
                              title:displayName
                             detail:[NSString stringWithFormat:DOLocalizedString(@"Health_Package_Manager_Healthy_Detail"), version]
                              state:DORootHideHealthStateHealthy
                          canRepair:NO];
}

- (DORootHideHealthItem *)injectionHealthItem
{
    if ([self.fileManager fileExistsAtPath:JBROOT_PATH(@"/basebin/.safe_mode")]) {
        return [self itemWithIdentifier:DORootHideHealthIdentifierInjection
                                  title:DOLocalizedString(@"Health_Injection")
                                 detail:DOLocalizedString(@"Health_Injection_Disabled_Detail")
                                  state:DORootHideHealthStateDisabled
                              canRepair:NO];
    }

    uint64_t brand = [self currentJailbreakBrand];
    NSString *brandedName = [NSString stringWithFormat:@"systemhook-%016llX.dylib", brand];
    NSString *brandedPath = [JBROOT_PATH(@"/basebin") stringByAppendingPathComponent:brandedName];
    if (brand != 0 && [self.fileManager fileExistsAtPath:brandedPath]) {
        return [self itemWithIdentifier:DORootHideHealthIdentifierInjection
                                  title:DOLocalizedString(@"Health_Injection")
                                 detail:[NSString stringWithFormat:DOLocalizedString(@"Health_Injection_Healthy_Detail"), brandedName]
                                  state:DORootHideHealthStateHealthy
                              canRepair:NO];
    }

    NSString *fixedPath = JBROOT_PATH(@"/basebin/systemhook.dylib");
    NSString *detail = [self.fileManager fileExistsAtPath:fixedPath]
        ? DOLocalizedString(@"Health_Injection_Pending_Detail")
        : DOLocalizedString(@"Health_Injection_Missing_Detail");
    return [self itemWithIdentifier:DORootHideHealthIdentifierInjection
                              title:DOLocalizedString(@"Health_Injection")
                             detail:detail
                              state:DORootHideHealthStateWarning
                          canRepair:NO];
}

- (NSArray<DORootHideHealthItem *> *)unknownHealthItems
{
    NSArray<NSDictionary *> *definitions = @[
        @{ @"Identifier" : DORootHideHealthIdentifierBootstrap, @"Title" : DOLocalizedString(@"Health_Bootstrap") },
        @{ @"Identifier" : DORootHideHealthIdentifierJailbreakApps, @"Title" : DOLocalizedString(@"Health_Jailbreak_Apps") },
        @{ @"Identifier" : DORootHideHealthIdentifierSileo, @"Title" : @"Sileo" },
        @{ @"Identifier" : DORootHideHealthIdentifierZebra, @"Title" : @"Zebra" },
        @{ @"Identifier" : DORootHideHealthIdentifierInjection, @"Title" : DOLocalizedString(@"Health_Injection") },
    ];
    NSMutableArray *items = [NSMutableArray new];
    for (NSDictionary *definition in definitions) {
        [items addObject:[self itemWithIdentifier:definition[@"Identifier"]
                                            title:definition[@"Title"]
                                           detail:DOLocalizedString(@"Health_Scan_Unavailable_Detail")
                                            state:DORootHideHealthStateUnknown
                                        canRepair:NO]];
    }
    return items;
}

- (NSArray<DORootHideHealthItem *> *)scanHealth
{
    __block NSArray<DORootHideHealthItem *> *items = nil;
    DOEnvironmentManager *environment = [DOEnvironmentManager sharedManager];
    [environment runAsRoot:^{
        [environment runUnsandboxed:^{
            items = @[
                [self bootstrapHealthItem],
                [self jailbreakApplicationsHealthItem],
                [self packageManagerHealthItemForKey:DORootHideHealthIdentifierSileo],
                [self packageManagerHealthItemForKey:DORootHideHealthIdentifierZebra],
                [self injectionHealthItem],
            ];
        }];
    }];
    return items ?: [self unknownHealthItems];
}

- (NSError *)repairRegistrationForPath:(NSString *)expectedPath bundleIdentifier:(NSString *)bundleIdentifier
{
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]];
    if (![info[@"CFBundleIdentifier"] isEqualToString:bundleIdentifier]) {
        return [self errorWithDescription:DOLocalizedString(@"Health_Repair_Invalid_Bundle")];
    }

    NSDictionary *userConflicts = [self userApplicationPathsForBundleIdentifiers:[NSSet setWithObject:bundleIdentifier]];
    if (userConflicts[bundleIdentifier]) {
        return [self errorWithDescription:DOLocalizedString(@"Health_Repair_User_App_Conflict")];
    }

    NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
    if (registeredPath.length && ![self path:registeredPath equalsPath:expectedPath]) {
        if (![self isRootHideManagedApplicationPath:registeredPath]) {
            return [self errorWithDescription:DOLocalizedString(@"Health_Repair_User_App_Conflict")];
        }
        int unregisterResult = exec_cmd(JBROOT_PATH("/usr/bin/uicache"), "-u", registeredPath.fileSystemRepresentation, NULL);
        if (unregisterResult != 0) {
            return [self errorWithDescription:[NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Unregister_Failed"), unregisterResult]];
        }
    }

    int registerResult = exec_cmd(JBROOT_PATH("/usr/bin/uicache"), "-p", expectedPath.fileSystemRepresentation, NULL);
    if (registerResult != 0 || ![self waitForBundleIdentifier:bundleIdentifier registeredAtPath:expectedPath]) {
        return [self errorWithDescription:[NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Register_Failed"), registerResult]];
    }
    return nil;
}

- (NSError *)repairJailbreakApplications
{
    DORootHideHealthItem *current = [self jailbreakApplicationsHealthItem];
    if (current.state == DORootHideHealthStateConflict || current.state == DORootHideHealthStateWarning) {
        return [self errorWithDescription:current.detail];
    }
    if (!current.canRepair) return nil;

    for (NSDictionary *record in [self jailbreakApplicationRecords]) {
        NSString *bundleIdentifier = record[@"BundleIdentifier"];
        NSString *expectedPath = record[@"Path"];
        if (bundleIdentifier.length == 0) continue;
        NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
        if ([self path:registeredPath equalsPath:expectedPath]) continue;
        NSError *error = [self repairRegistrationForPath:expectedPath bundleIdentifier:bundleIdentifier];
        if (error) return error;
    }
    return nil;
}

- (NSError *)repairPackageManagerWithKey:(NSString *)key
{
    DORootHideHealthItem *current = [self packageManagerHealthItemForKey:key];
    if (current.state == DORootHideHealthStateConflict || !current.canRepair) {
        return current.state == DORootHideHealthStateHealthy ? nil : [self errorWithDescription:current.detail];
    }

    NSDictionary *configuration = [self packageManagerConfigurationForKey:key];
    NSString *debianPackage = configuration[@"Debian Package"];
    NSString *applicationName = configuration[@"Application"];
    if (!configuration || debianPackage.length == 0 || applicationName.length == 0) {
        return [self errorWithDescription:DOLocalizedString(@"Health_Package_Manager_Config_Missing_Detail")];
    }
    NSString *expectedPath = [JBROOT_PATH(@"/Applications") stringByAppendingPathComponent:applicationName];
    NSDictionary *packageInfo = [self installedPackageInfoForIdentifier:debianPackage];
    NSDictionary *appInfo = [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]];
    BOOL enabled = [[[DOUIManager sharedInstance] enabledPackageManagerKeys] containsObject:key];
    NSString *registeredPath = [self registeredPathForBundleIdentifier:key];
    BOOL appExists = [self.fileManager fileExistsAtPath:expectedPath];

    // A package manager that the user did not select may leave only an old
    // LaunchServices record behind. Remove that record; do not surprise the
    // user by reinstalling the package.
    if (!enabled && ![self isPackageInstalled:packageInfo] && !appExists &&
        registeredPath.length && [self isRootHideManagedApplicationPath:registeredPath]) {
        int unregisterResult = exec_cmd(JBROOT_PATH("/usr/bin/uicache"), "-u", registeredPath.fileSystemRepresentation, NULL);
        if (unregisterResult != 0 || ![self waitForBundleIdentifier:key registeredAtPath:nil]) {
            return [self errorWithDescription:[NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Unregister_Failed"), unregisterResult]];
        }
        return nil;
    }

    BOOL requiresInstall = ![self isPackageInstalled:packageInfo] || ![appInfo[@"CFBundleIdentifier"] isEqualToString:key];

    if (requiresInstall) {
        NSString *packagePath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:configuration[@"Package"]];
        if (![self.fileManager fileExistsAtPath:packagePath]) {
            return [self errorWithDescription:DOLocalizedString(@"Health_Repair_Bundled_Package_Missing")];
        }
        int installResult = exec_cmd_trusted(JBROOT_PATH("/usr/bin/dpkg"), "-i", packagePath.fileSystemRepresentation, NULL);
        if (installResult != 0) {
            return [self errorWithDescription:[NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Install_Failed"), installResult]];
        }
    }

    return [self repairRegistrationForPath:expectedPath bundleIdentifier:key];
}

- (NSError *)repairItemWithIdentifier:(NSString *)identifier
{
    if (![identifier isEqualToString:DORootHideHealthIdentifierJailbreakApps] &&
        ![identifier isEqualToString:DORootHideHealthIdentifierSileo] &&
        ![identifier isEqualToString:DORootHideHealthIdentifierZebra]) {
        return [self errorWithDescription:DOLocalizedString(@"Health_Repair_Not_Available")];
    }

    __block NSError *repairError = nil;
    __block BOOL didRun = NO;
    DOEnvironmentManager *environment = [DOEnvironmentManager sharedManager];
    [environment runAsRoot:^{
        [environment runUnsandboxed:^{
            didRun = YES;
            if ([identifier isEqualToString:DORootHideHealthIdentifierJailbreakApps]) {
                repairError = [self repairJailbreakApplications];
            }
            else {
                repairError = [self repairPackageManagerWithKey:identifier];
            }
        }];
    }];

    if (!didRun) return [self errorWithDescription:DOLocalizedString(@"Health_Repair_Privilege_Failed")];
    return repairError;
}

@end
