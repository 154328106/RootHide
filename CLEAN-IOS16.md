# RootHide iOS 16 clean build

## Scope

- Runtime target: iOS 16.0 through 16.6.1 on arm64e (A12 through A16).
- Base: the locally validated `roothide-3.0.7-stable` branch.
- UI: the validated layout is preserved, with an additional RootHide Health
  page under Settings while jailbroken.
- RootHide core: randomized JBROOT, randomized SystemHook paths, blacklist and
  conflict detection, injection, XPF, ChOma, opainject and litehook remain on
  the validated versions.

The support gate lives in `DOEnvironmentManager` in addition to the exploit
metadata. Bundling an exploit with wider metadata therefore cannot silently
enable iOS 15, iOS 17 or non-arm64e devices.

## Dopamine 3.0.9 audit

The official 3.0.7 to 3.0.9 delta was reviewed commit by commit.

Included:

- The TrollStore-only direct uninstall rule from 3.0.8. The trash-button path
  is available only while not jailbroken; the reboot-to-remove workflow stays
  available while jailbroken. This was already ported in commit `4bd3c30`.

Not included:

- iOS 18.0 through 18.4+ icon database rebuild changes. They cannot run on the
  target and add private API surface.
- Hide Jailbreak text and settings presentation changes. RootHide uses its own
  hiding model and the existing UI is intentionally preserved.
- Version-only 3.0.8 and 3.0.9 commits. This build does not claim an upstream
  core version it does not contain.
- Removal of the short userspace-reboot and respring sleeps. RootHide has its
  own lifecycle timing, so the validated delays remain.

## Cleanups and stability changes

- The packaged exploit set is limited to kfd/landa (kernel), dmaFail, Titan and
  momentarius (PPL). iOS 15-only badRecovery, weightBufs and multicast_bytecopy,
  the redundant ClearSword/DarkSword alternatives, and palera1n are removed
  from the final app bundle.
- palehide detection, marker creation and A11 runtime hooks are removed. The
  old action number and jailbreak-info field remain reserved so the internal
  protocol and serialized layout do not shift.
- Existing checks for another active jailbreak remain. Those are conflict
  detection, not a palera1n runtime dependency.
- Spawn attributes are checked and destroyed on both success and failure.
- Caller-owned spawn flags are restored after RootHide temporarily adds
  `POSIX_SPAWN_START_SUSPENDED`.
- The launchd handoff thread owns a heap context instead of a caller stack
  object, releases received XPC objects, and exits when its receive port dies.
- launchd primitive handoff now fails after 30 seconds instead of blocking the
  app forever.
- jbctl exit status is validated before opainject begins.
- The userspace-reboot boomerang receive right remains alive after its initial
  `DONE` reply because boomerang still needs that server to patch the successor
  launchd. Releasing only the local send right preserves the validated RootHide
  lifecycle and prevents a black screen during userspace reboot.

## Preserved hardening

- TrustCache allocation bounds, deduplication, head zeroing and the 3.0.7
  out-of-bounds kernel-write fix.
- SPTM/TXM TrustCache insertion behavior already present in the stable branch.
- Automatic recovery from a corrupted `basebin/gen/dyld.old`.
- The current jailbreakd port/XPC/launchd readiness gate.
- Titan/landa offsets, ROP chain and exploit timing used by the A16/iOS 16.6.1
  validated path.

## RootHide Health and precise repair

- The unified page checks Bootstrap, jailbreak app registration, Sileo,
  Zebra, and the RootHide injection hook. Checks are read-only and run only
  while the jailbreak is active.
- Jailbreak app repair uses targeted `uicache -p` registration. A stale entry
  is unregistered only when its path matches a randomized RootHide
  `.jbroot-<16 hex>` application path.
- Real user-app paths, non-RootHide registrations, duplicate jailbreak Bundle
  IDs, invalid Info.plists, and other ambiguous states block automatic repair.
- Sileo and Zebra are checked independently against dpkg status, their exact
  app bundle and Bundle ID, and LaunchServices registration. A bundled deb is
  installed only when that manager's package or app bundle is missing or
  invalid; registration-only faults never trigger a reinstall.
- Safe Mode is reported as injection intentionally disabled. Injection health
  validates `systemhook-<16 hex>.dylib` for the current `jbrand` and does not
  attempt to rewrite RootHide core files.
- LC_RPATH metadata caching is deliberately not included in this stable
  change.

## Device validation required

A successful build is not proof of runtime stability. Before publishing, test
at least: first jailbreak, rejailbreak, userspace reboot, respring, safe mode,
TrollStore uninstall while unjailbroken, remove-jailbreak through the supported
toggle workflow, failed exploit retry, and a forced launchd handoff failure.
For Health, additionally test missing and stale app registration, a real user
App Bundle ID collision, Sileo-only and Zebra-only installations, an
unselected manager, and a missing package-manager app bundle.
