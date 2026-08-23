# RootHide iOS 16 clean build

## Scope

- Runtime target: iOS 16.0 through 16.6.1 on arm64e (A12 through A16).
- Base: the locally validated `roothide-3.0.7-stable` branch.
- UI: unchanged from that branch.
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

## Preserved hardening

- TrustCache allocation bounds, deduplication, head zeroing and the 3.0.7
  out-of-bounds kernel-write fix.
- SPTM/TXM TrustCache insertion behavior already present in the stable branch.
- Automatic recovery from a corrupted `basebin/gen/dyld.old`.
- The current jailbreakd port/XPC/launchd readiness gate.
- Titan/landa offsets, ROP chain and exploit timing used by the A16/iOS 16.6.1
  validated path.

## Device validation required

A successful build is not proof of runtime stability. Before publishing, test
at least: first jailbreak, rejailbreak, userspace reboot, respring, safe mode,
TrollStore uninstall while unjailbroken, remove-jailbreak through the supported
toggle workflow, failed exploit retry, and a forced launchd handoff failure.
