# Optimizing `UIBezierPathProperties` cache allocations

## Background

Every `UIBezierPath` in a process linked against PerformanceBezier carries an associated `UIBezierPathProperties` object (set up via `objc_setAssociatedObject` with key `BEZIER_PROPERTIES` in `UIBezierPath+Performance.m:30`). The properties object holds four manually-managed C arrays:

| ivar | element type | size/element | invalidation |
|---|---|---|---|
| `elementLengthCache` | `LengthCacheItem {CGFloat acceptableError; CGFloat length;}` | 16 B | per-element on mutation |
| `totalLengthCache` | `LengthCacheItem` | 16 B | per-element on mutation |
| `elementPositionChangeCache` | `ElementPositionChange` (enum) | ~4 B | per-element on mutation |
| `subpathRanges` | `NSRange` | 16 B | reset count on mutation |

All four are allocated lazily on first write via `calloc` (see `UIBezierPathProperties.m:181`, `:220`, `:244`, `:287`), and grown on overflow with the pattern:

```c
const NSInteger DefaultCount = MAX(256, pow(2, log2(index + 1) + 1));
elementLengthCache = calloc(DefaultCount, sizeof(LengthCacheItem));
lengthCacheCount = DefaultCount;
```

The growth path (`memcpy` then `free` of the old buffer) is correct and safe. The 256-slot floor is the issue.

## The problem

The 256-slot floor means **every cached path pays a flat tax that has nothing to do with its actual size**. For typical UI paths (a handful to a few dozen elements), more than 95% of every cache buffer is wasted.

### Per-instance footprint, fully populated

| Cache | Slots | Bytes |
|---|---|---|
| `elementLengthCache` | 256 | 4096 |
| `totalLengthCache` | 256 | 4096 |
| `elementPositionChangeCache` | 256 | 1024 |
| `subpathRanges` | 256 | 4096 |
| **Total** | | **13,312 B (~13 KB)** |

Note: each cache only allocates if its API is called. A path you only ever read `firstPoint`/`bounds`/`elementCount` on pays 0. A path queried for `length` pays for the first two (`elementLengthCache` + `totalLengthCache` = 8 KB). `subpathRangeForElement:` adds the fourth.

### Per-instance footprint, right-sized for a 100-element path

`subpathRanges` is keyed by **subpath count**, not element count — a 100-element path typically has 1–3 subpaths.

| Cache | Slots | Bytes |
|---|---|---|
| `elementLengthCache` | 100 | 1600 |
| `totalLengthCache` | 100 | 1600 |
| `elementPositionChangeCache` | 100 | 400 |
| `subpathRanges` | 4 | 64 |
| **Total** | | **3,664 B (~3.6 KB)** |

**Savings: ~9.6 KB per fully-populated path, ~72%.** For length-only callers, ~5 KB / ~61%.

> Note: this table shows what a perfectly-sized cache would cost. Proposal A as shipped keeps a 16-slot floor on every cache, so a path with 1–3 subpaths still allocates 16 `NSRange` slots (256 B) for `subpathRanges`. Proposal B (size to element count) closes most of the remaining gap.

### Allocator rounding caveat

`libmalloc`'s small zone rounds in 512-byte buckets, tiny in 16-byte. After rounding:

- 1600 B → ~2048 B (small zone)
- 400 B → ~416 B (tiny zone)
- 64 B → 64 B (tiny zone)

Real per-instance cost ≈ 4576 B, vs. current 13,312 B. **Still ~65% saved.**

### Scaling

This compounds with path cardinality, not just per-path size:

- 1,000 paths × 100 elements: **13 MB → 4.5 MB**
- 10,000 paths × 100 elements: **130 MB → 45 MB**

For drawing/vector apps with large stroke libraries, this is the difference between fitting in memory and not.

## Why the current shape exists

The 256 floor was almost certainly chosen so that small paths don't reallocate repeatedly as elements get appended. That's reasonable in principle but pessimistic for two reasons:

1. **The growth path already handles overflow well.** It doubles, with `memcpy`. So even starting at 16, you reach 256 in 4 reallocations — and most paths never need to.
2. **By the time the first cache write happens, `cachedElementCount` is usually known.** Length and position-change queries iterate the path; we know how big the cache should be before we allocate it.

## Copies don't share these caches

Confirmed by reading `swizzle_copy` in `UIBezierPath+Performance.m:715`: only the **scalar** properties are copied to the destination's fresh `UIBezierPathProperties`. The four C arrays start empty on the copy. So copy-heavy workflows pay the 256-floor tax once per copy, even when the copy and original have identical geometry.

This is correct for safety (mutating a copy must not corrupt the original's cache), but it means per-path allocation efficiency matters even more in copy-heavy code.

## Proposal A: minimal change — drop the floor

The smallest possible fix:

```c
const NSInteger DefaultCount = MAX(16, pow(2, log2(index + 1) + 1));
```

(or just `MAX(8, ...)` — 8 is the smallest power-of-two that survives a few cheap appends.)

**Pros:** one-line change per cache, behavior identical for paths that grow past 256, near-perfect proportionality for small paths.

**Cons:** a path that *does* grow to ~200 elements pays a few extra reallocations during its lifetime. In the steady state this is invisible (caches are write-once-per-element-per-error-tolerance), but it means a few extra `calloc`/`memcpy` pairs while the path is being built.

This is probably the right first move. It's a one-character change per cache and eliminates ~65% of the waste.

## Proposal B: size to known element count on first write

When the first cache write happens, we usually know how many elements the path has — `cachedElementCount` is set after the first `elementCount` call (and is set eagerly by many of the swizzles). For length queries specifically, the caller has already iterated the path, so we know the size exactly.

```c
if (lengthCacheCount == 0) {
    NSInteger known = self.cachedElementCount; // 0 if not yet known
    NSInteger initial = MAX(MAX(8, known), index + 1);
    elementLengthCache = calloc(initial, sizeof(LengthCacheItem));
    lengthCacheCount = initial;
}
```

**Pros:** zero reallocations for typical use (allocate exactly the right size on first write). No growth pressure. Drop-in.

**Cons:** slightly more code per cache. `cachedElementCount` may be 0 if no one has called `elementCount` yet — falls back to a small floor.

## Proposal C: single calloc, four contiguous arrays

You asked about consolidating the allocations. Here's what that looks like.

The three element-indexed caches (`elementLengthCache`, `totalLengthCache`, `elementPositionChangeCache`) all share the same indexing scheme: `[0, elementCount)`. They all grow together — when the path adds an element, conceptually all three caches gain a slot. They all get freed together. They could share a single allocation.

`subpathRanges` is **not** element-indexed (it's subpath-indexed and grows with `subpathRangesNextIndex`), so it should stay separate.

### Layout

Define a struct that bundles the per-element data:

```c
typedef struct ElementCacheEntry {
    CGFloat elementLength;        // -1 = unset
    CGFloat elementLengthError;
    CGFloat totalLength;          // -1 = unset
    CGFloat totalLengthError;
    ElementPositionChange positionChange; // 0 = unknown
} ElementCacheEntry;
```

`sizeof(ElementCacheEntry)` ≈ 40 B (with padding). For a 100-element path that's 4000 B in one allocation, vs. 1600 + 1600 + 400 = 3600 B in three separate allocations — almost the same after libmalloc rounding (the three separate allocations round to 2048 + 2048 + 416 = ~4500 B in the small/tiny zones).

### Pros

- **One allocation per path instead of three.** Halves allocator overhead and metadata.
- **Better cache locality.** The three lookups for a single element index now hit one cache line instead of three.
- **Simpler grow logic.** One `calloc` + `memcpy` + `free` site instead of three near-identical copies.
- **One free in `dealloc`.** Less code, less to get wrong.
- **One sentinel-handling convention.** Use `-1` for unset lengths (already the API contract), `0` for unknown position change (already `kPositionChangeUnknown`).

### Cons

- **Padding waste.** `ElementCacheEntry` packs poorly (5 mixed-size fields). With explicit packing or reordering, you can land on ~40 B. Compare to 16 + 16 + 4 = 36 B raw — padding eats 4 B per slot. For a 100-element path, that's 400 B. Acceptable.
- **All-or-nothing allocation.** A path that only ever queries `elementLength` (never `totalLength`, never `changesPosition`) currently pays for one cache. With the consolidated layout it pays for all three slot fields, even unused ones. For 100 elements this is 4000 B vs. 1600 B — **the consolidated form is worse for this case** by ~2.4 KB.
- **Separate `acceptableError` per cache becomes awkward.** Currently `elementLengthCache[i].acceptableError` and `totalLengthCache[i].acceptableError` are independent. Consolidating means each entry stores both errors (still works, just two fields per entry as shown above).

### Verdict

**Proposal C is a wash for memory** unless callers always populate all three caches. The locality and simplicity wins are real, but they're paid for by losing the lazy per-cache allocation. Worth doing only if profiling shows that all three caches are usually populated together (which seems likely — most callers go from `elementCount` → `length` → element-by-element analysis), or if allocator metadata overhead matters at high path counts.

**For a 10,000-path workload** the metadata savings might actually matter: 30,000 small allocations → 10,000 means ~20,000 fewer slab entries, fewer alloc-time locks, faster `dealloc`.

## Recommendation

Tackle in two stages:

1. **Ship Proposal A first.** One-line change per cache, ~65% memory reduction on small paths, no behavior change. Low risk, immediate win.
2. **Measure before doing B or C.** If `Instruments` shows allocator pressure or significant time in `calloc` during path construction, layer Proposal B on top. Save Proposal C for when there's evidence the allocator overhead matters at scale — e.g. `xctrace` shows many `_malloc_zone_malloc` calls on the path-construction hot path.

The thing **not** to do is jump straight to Proposal C — the lazy per-cache allocation is currently a strength (a path that only needs `length` only pays for `length`'s caches), and consolidating loses that without a measured win.

## Out of scope but related

- **`subBezierLengthCache` in `+subdivideBezier:atLength:…`** (`UIBezierPath+Util.m:152`) is a flat 8 KB `calloc(1000)` allocated per call when the caller doesn't pass one. That's a separate optimization opportunity (the cache is sparse — most slots stay zero) but unrelated to per-path memory.
- **`elementCacheArray`** (`UIBezierPath+NSOSX.m:60`) is a deep allocation per `CGPathElement` (one `malloc` for the struct, another for `points`). Consolidating *that* — one big allocation indexed by element — would be a much bigger win for paths with many elements, since each element currently costs 2 allocations + `NSValue` boxing + array entry. Worth its own writeup.

## File references

- `PerformanceBezier/UIBezierPathProperties.h:11–16` — `LengthCacheItem`/`ElementPositionChange` types
- `PerformanceBezier/UIBezierPathProperties.m:131–162` — `dealloc` (frees all four arrays)
- `PerformanceBezier/UIBezierPathProperties.m:181–201` — `cacheLength:forElementIndex:` (the canonical grow pattern)
- `PerformanceBezier/UIBezierPath+Performance.m:715–737` — `swizzle_copy` (does not transfer C-array caches)
