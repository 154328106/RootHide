# A16 / iOS 16.6.1 hardening notes

Target: iPhone 14 Pro Max (A16), iOS 16.6.1.

This branch intentionally keeps the already validated landa + Titan exploit path,
offsets, ROP chain, and timing unchanged.

Hardening changes:

- remove public runtime logging of jailbreak root and injection paths;
- retain only privacy-redacted failure diagnostics;
- reset and validate Titan initialization state;
- validate OS/CPU discovery, wait-thread creation, and GFX L1 buffer operations;
- clean up Titan context when a run fails;
- run the full TIPA build for branch pushes.

Runtime behavior still requires device testing. A successful CI build only proves that
the source compiles and packages correctly.
