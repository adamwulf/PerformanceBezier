# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

PerformanceBezier is an Objective-C framework that adds caching and NSBezierPath-style API to `UIBezierPath` on iOS. It is distributed as both a CocoaPod (`PerformanceBezier.podspec`) and a Swift Package (`Package.swift`). Platform is iOS only (deployment target 10.0, `SDKROOT = iphoneos`, universal device family).

The library installs itself globally: clients link the framework and `#import <PerformanceBezier/PerformanceBezier.h>`, and from then on every `UIBezierPath` instance in the process is upgraded — no opt-in API, no custom subclass.

## Build & test

The Xcode project and the SwiftPM manifest produce the same module from the same sources under `PerformanceBezier/`.

```sh
# Build the framework via Xcode (iOS Simulator)
xcodebuild -project PerformanceBezier.xcodeproj -scheme PerformanceBezier -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run the full test suite (XCTest target PerformanceBezierTests)
xcodebuild -project PerformanceBezier.xcodeproj -scheme PerformanceBezier -destination 'platform=iOS Simulator,name=iPhone 15' test

# Run a single test class or method
xcodebuild -project PerformanceBezier.xcodeproj -scheme PerformanceBezier -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:PerformanceBezierTests/PerformanceBezierTrimTest test
xcodebuild -project PerformanceBezier.xcodeproj -scheme PerformanceBezier -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:PerformanceBezierTests/PerformanceBezierTrimTest/testSomeMethod test

# SwiftPM build (compiles the library target only — tests need Xcode because they're an iOS XCTest bundle)
swift build
```

Clients linking the framework (not via SwiftPM) must add `-ObjC++ -lstdc++` to Other Linker Flags — see the podspec's `OTHER_LDFLAGS`. The C++ standard is `gnu++0x` with `libc++`.

Code style is enforced by `.clang-format` (Google-derived, 4-space indent, no column limit, Linux braces, `ObjCSpaceAfterProperty: false`).

## Architecture

### How the caching gets installed

There is no `PBPath` subclass. Instead, `+[UIBezierPath load]` in `UIBezierPath+Performance.m` swizzles a long list of `UIBezierPath` instance and class methods (`moveToPoint:`, `addLineToPoint:`, `addCurveToPoint:...`, `addQuadCurveToPoint:...`, `closePath`, `bounds`, `copy`, `appendPath:`, `applyTransform:`, `removeAllPoints`, `dealloc`, `initWithCoder:`, `encodeWithCoder:`, all the `bezierPathWith…` factories, etc.). Every mutation goes through a `swizzle_…` method that updates a per-instance cache before delegating to the original implementation.

Swizzling is done through `JRSwizzle.{h,m}` (vendored, MIT-licensed) via the `mmpb_swizzleMethod:` / `mmpb_swizzleClassMethod:` helpers.

### The per-instance cache

Each `UIBezierPath` is associated (via `objc_setAssociatedObject` with key `BEZIER_PROPERTIES`) with a `UIBezierPathProperties` object (see `UIBezierPathProperties.{h,m}`). It stores:

- `firstPoint` / `lastPoint` (with `hasFirstPoint` / `hasLastPoint` flags so absence is distinguishable from `CGPointZero`)
- `bounds`, `isFlat`, `isClosed` (with a `knowsIfClosed` flag)
- `tangentAtEnd`, `cachedElementCount`, `lastAddedElementWasMoveTo`
- A retained `bezierPathByFlatteningPath` (memoized flattened copy, see `UIBezierPath+Ahmed`)
- Per-element keyed caches: length-of-element, length-through-element, "does this element change position", subpath-range — looked up by `elementIndex` and `acceptableError`
- A free-form `userInfo` dictionary

Mutation methods invalidate fields they touch; readers (`firstPoint`, `lastPoint`, `length`, `isClosed`, `bounds`, `elementCount`, `elementAtIndex:`, …) lazy-fill the cache and return.

Separately, `UIBezierPath+NSOSX` keeps an associated `NSMutableArray *elementCacheArray` (key `ELEMENT_ARRAY`) of malloc'd `CGPathElement *` to give O(1) `elementAtIndex:` lookups (CoreGraphics only exposes `CGPathApply`). This array owns its memory and is freed in `freeCurrentElementCacheArray` / on swizzled `dealloc`.

### File map

- `UIBezierPath+Performance.{h,m}` — public performance API (`firstPoint`, `lastPoint`, `length`, `tangentAtEnd`, `isClosed`, per-element length / tangent / fillBezier, `subpathRangeForElement:`, `changesPositionDuringElement:`) **and** all the swizzle implementations + `+load`.
- `UIBezierPath+NSOSX.{h,m}` — NSBezierPath-style accessors (`elementCount`, `elementAtIndex:`, `setAssociatedPoints:atIndex:`, `iteratePathWithBlock:`, `controlPointBounds`).
- `UIBezierPath+Ahmed.{h,m}` — flattening per Ahmad's MS thesis (cached `bezierPathByFlatteningPath`).
- `UIBezierPath+Trim.{h,m}` — trim-by-element/T-value, plus `+subdivideBezier:intoLeft:andRight:atT:` / `…atLength:…`.
- `UIBezierPath+FirstLast`, `+Center`, `+Clockwise`, `+Description`, `+Equals`, `+Util` — focused helper categories.
- `UIBezierPath+Uncached.{h,m}` — only relevant when compiled with `-DMMPreventBezierPerformance`; lets benchmarks see the un-cached path.
- `UIBezierPath+*_Private.h`, `JRSwizzle.h`, `UIBezierPath+FirstLast.h` — private to the module, listed under `private header` in `module.modulemap` and `private_header_files` in the podspec.
- `PerformanceBezier.h` — umbrella header; `#define CGPointNotFound CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)` lives here.

### Module layout

`Package.swift` exposes the entire `PerformanceBezier/` directory with `publicHeadersPath: "."`. The `module.modulemap` declares `PerformanceBezier.h` as the umbrella and explicitly marks the `_Private.h` headers, `JRSwizzle.h`, `UIBezierPath+Uncached.h`, and `UIBezierPath+FirstLast.h` as `private header` so they are excluded from the umbrella module.

### Conventions to preserve

- Don't introduce a `UIBezierPath` subclass — the framework's contract is "any `UIBezierPath` is fast." New caching belongs as more associated state on `UIBezierPathProperties` plus invalidation in the matching `swizzle_…` method.
- Any new mutating swizzle must invalidate the affected cache fields **and** call the original (`[self swizzle_…]`) before returning.
- Keep public/private header status in sync between `module.modulemap` and `PerformanceBezier.podspec` (`public_header_files` / `private_header_files`) when adding/moving headers.
- Tests subclass `PerformanceBezierAbstractTest` (`PerformanceBezierTests/`) and use `@import PerformanceBezier;`.
