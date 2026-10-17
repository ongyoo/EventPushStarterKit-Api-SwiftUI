# App size

Small apps download faster, install more often on cellular, launch faster and
use less memory. This kit is built to stay small; this page shows where the
bytes go and how to keep it that way.

## Current size (Release, iPhone arm64)

Measured with `make size`:

| Metric | Size |
|---|---|
| **Download (compressed, estimate)** | **≈ 1.5 MB** |
| Install size (symbols stripped, as shipped) | ≈ 3.9 MB |
| Executable (stripped) | ≈ 3.8 MB |
| Resources (strings, fixtures, storyboards, Info.plist) | ≈ 0.1 MB |
| Embedded frameworks | **0** (everything is linked statically) |

Who uses the code + data (before compression):

| Owner | Size | Share |
|---|---|---|
| Kingfisher (image loading & cache) | ≈ 1.1 MB | 33 % |
| Alamofire (networking) | ≈ 1.1 MB | 32 % |
| Modules / Features (all screens) | ≈ 0.34 MB | 10 % |
| Modules / DataSources + Platform | ≈ 0.20 MB | 6 % |
| Modules / DesignSystem | ≈ 0.18 MB | 5 % |
| Modules / Core | ≈ 0.10 MB | 3 % |
| Modules / Navigation | ≈ 0.06 MB | 2 % |
| Modules / Domain, DataLayer, App | ≈ 0.15 MB | 4 % |
| App target, linker | ≈ 0.14 MB | 4 % |

Splitting into one module per layer cost nothing: modules are linked
statically into one executable (download ≈ 1.49 MB before and after).

Numbers change as features grow: always re-measure with `make size`.

> Xcode's unstripped Release build is ~8.5 MB because it still contains debug
> symbols (`__LINKEDIT`). Archiving strips them (`STRIP_INSTALLED_PRODUCT = YES`
> in `Config/Release.xcconfig`); the table shows the stripped size.

## What keeps it small

| Choice | Effect |
|---|---|
| **2 third-party libraries only**, no Firebase/Rx/SnapKit/Lottie | Each big SDK adds 1–10 MB |
| **In-house DI** (`Container`, ~100 lines) instead of a DI library | No extra framework |
| **Static linking** (Swift Package products) | No dynamic frameworks to load: smaller and faster launch |
| `DEAD_CODE_STRIPPING = YES` | Unused code removed at link time |
| Release: `-O`, whole-module optimization, symbols stripped | Smaller and faster code |
| **System frameworks for system features** (MetricKit, BGTaskScheduler, SwiftData, CryptoKit, ActivityKit, App Intents) | Already on the device: 0 bytes |
| **Sample images removed** (17 MB of unused assets) | Images come from the network, cached by Kingfisher |
| Feature flags (`Config/Features.xcconfig`) | App-target code for Siri / push is compiled out when off |
| SF Symbols for icons | No icon assets |
| String Catalogs | Only the languages you ship |

## Rules for the team

1. **Ask before adding a dependency.** Check its size first (`make size` before
   and after on a branch). Prefer the system framework when one exists.
2. **No images in the app bundle for content.** Load them from the server
   (`RemoteImage`). Bundle only small UI assets, as vector PDF/SVG in asset catalogs.
3. **Large optional assets** (onboarding videos, ML models, fonts for one
   feature): use On-Demand Resources or download them when needed.
4. **Fonts:** subset them; ship only the weights you use.
5. **Keep the budget in CI:** `MAX_DOWNLOAD_KB=3000 make size` fails the build
   when the download estimate passes 3 MB.

## Want it even smaller?

Two thirds of the code is Alamofire + Kingfisher. Both are hidden behind our
own APIs, so they can be replaced without touching features:

| Swap | Saves (approx.) | Work |
|---|---|---|
| Alamofire → `URLSession` | ~1.1 MB before compression (~0.4 MB download) | Rewrite `AlamofireAPIClient` (one file) as `URLSessionAPIClient`, incl. pinning via `URLSessionDelegate` |
| Kingfisher → `AsyncImage` + `URLCache` | ~1.1 MB before compression (~0.4 MB download) | Rewrite `RemoteImage` (one file); you lose downsampling and the disk cache tuning |

Keep them unless size is critical: they bring robust caching, retries,
downsampling and SSL pinning that would otherwise be your code to maintain.

## Measuring

```bash
make size                                  # build Release + report
MAX_DOWNLOAD_KB=3000 make size             # fail above a budget (CI)
```

For the exact App Store numbers per device, archive in Xcode, then
**Distribute App → Custom → Development/Ad Hoc → App Thinning: All compatible device variants**:
the export contains `App Thinning Size Report.txt`.
