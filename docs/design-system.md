# Design system

The product uses one semantic color source of truth:
[`Shared/BrandColors.xcassets`](../Shared/BrandColors.xcassets). The iPhone, iPad, Mac,
Home Screen widget, and Apple Watch targets compile that catalog into their own bundles.

## Color model

Each color name describes a role rather than a pigment:

| Token | Role |
|---|---|
| `VTBackground` | Main practice field |
| `VTSurface` | Raised or grouped controls |
| `VTSelected` | Selected and pressed surfaces |
| `VTText` | Primary copy and timer numerals |
| `VTMuted` | Supporting copy and metadata |
| `VTBorder` | Quiet control boundaries |
| `AccentColor` | Primary action and active state |
| `VTPatina` | Secondary structure and circular marks |
| `VTButtonText` | Copy placed on the accent color |
| `VTNavigation` | Phone and Mac navigation field |
| `VTWidgetBackground` | Widget's intentionally dark field |
| `VTWidgetText` | Widget's warm primary copy |
| `VTWidgetAccent` | Widget action marks |

Since 2.0.0 the universal light and dark appearances carry the two Ganzfeld fields: **light
is Dawn** and **dark is Night**. They are one visual language at two times of day, not two
designs — identical hairlines, aperture and structure, with only the field inverted and the
ink following it. Because the skin is entirely a light/dark pair, following the system needs
no code, and an explicit choice is a single `.preferredColorScheme` at the root driven by the
`appearance` default. `VTField1`–`VTField5`, `VTAperture*` and `VTVignette*` describe the
field itself; the aperture's alpha is applied in code because it varies with session phase.

One asymmetry is deliberate and worth keeping: a light field needs **heavier** hairlines than
a dark one for the same perceived weight, so `VTBorder` is 58% ink in Dawn where it is 48%
white in Night. Inverting the alphas instead measured 2.49:1 and failed AA.

The Watch retains its own device variants for the intentional OLED near-black, warm-bone, moss,
sage, and clay treatment, unchanged by the 2.0.0 overhaul. The Watch remains dark-only by
design; it does not maintain a second palette in Swift.

The three widget roles keep their original always-dark treatment. They live in the same
catalog so widget colors are named tokens, not hardcoded RGB.

## Changing a color

- Use `Color("TokenName")` through `VTPalette` or `WatchPalette`; do not introduce inline RGB
  literals in product UI.
- Add a device-specific variation to the existing semantic color set when a platform needs a
  materially different pigment. Do not create an unrelated palette file.
- `scripts/make_app_icons.swift` reads the universal semantic colors and quantizes them to 8-bit
  sRGB, keeping generated icons deterministic and byte-for-byte stable.
- `DesignTokenTests` verifies that every Watch role has a Watch variant, that Watch and widget
  code contain no inline RGB colors, and that the icon generator consumes the shared catalog.
  The suite runs in SwiftPM, Xcode, and GitHub Actions.
- After changing a token, render light and dark phone layouts plus 40 mm and 46 mm Watch
  layouts, and re-check contrast, Dynamic Type, increased contrast, and reduced motion.

## Current Watch pigments

| Role | Value |
|---|---:|
| Background | `#10140F` |
| Surface | `#1B211A` |
| Selected | `#242D23` |
| Text | `#F1EBDD` |
| Muted | `#A8AD9F` |
| Border | `#333D31` |
| Accent | `#DA8059` |
| Patina | `#899B8B` |
| Button text | `#19120E` |

These values are recorded here for human review. The asset catalog, not this table, is the
executable source of truth.
